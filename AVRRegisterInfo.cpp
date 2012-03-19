//===- AVRRegisterInfo.cpp - AVR Register Information ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the AVR implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "avr-reg-info"

#include "AVR.h"
#include "AVRMachineFunctionInfo.h"
#include "AVRRegisterInfo.h"
#include "AVRTargetMachine.h"
#include "llvm/Function.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/Support/ErrorHandling.h"

#define GET_REGINFO_TARGET_DESC
#include "AVRGenRegisterInfo.inc"

using namespace llvm;

// FIXME: Provide proper call frame setup / destroy opcodes.
AVRRegisterInfo::AVRRegisterInfo(AVRTargetMachine &tm,
                                       const TargetInstrInfo &tii)
  : AVRGenRegisterInfo(AVR::PC), TM(tm), TII(tii) {
}

const unsigned*
AVRRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  const TargetFrameLowering *TFI = MF->getTarget().getFrameLowering();
  //const Function* F = MF->getFunction();
  static const unsigned CalleeSavedRegs[] = {
    AVR::R2, AVR::R3, AVR::R4, AVR::R5, AVR::R6,
    AVR::R7, AVR::R8, AVR::R9, AVR::R10, AVR::R11,
    AVR::R12, AVR::R13, AVR::R14, AVR::R15, AVR::R16, AVR::R17, 
    0
  };
  static const unsigned CalleeSavedRegsFP[] = {
    AVR::R28, AVR::R29, AVR::R2, AVR::R3, AVR::R4, AVR::R5, AVR::R6,
    AVR::R7, AVR::R8, AVR::R9, AVR::R10, AVR::R11,
    AVR::R12, AVR::R13, AVR::R14, AVR::R15, AVR::R16, AVR::R17,
    0
  };
  /*
  static const unsigned CalleeSavedRegsIntr[] = {
    0
  };
  static const unsigned CalleeSavedRegsIntrFP[] = {
    0
  };
  */

  // TODO : Change this when adding INTR calling conv
  if (TFI->hasFP(*MF))
    return (CalleeSavedRegsFP);
  else
    return (CalleeSavedRegs);
}

BitVector AVRRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();

  if (TFI->hasFP(MF))
    Reserved.set(AVR::Y);

  return Reserved;
}

const TargetRegisterClass *
AVRRegisterInfo::getPointerRegClass(unsigned Kind) const {
  return &AVR::GR16RegClass;
}

void AVRRegisterInfo::
eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator I) const {
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();

  if (!TFI->hasReservedCallFrame(MF)) {
    MachineInstr *Old = I;
    uint64_t Amount = Old->getOperand(0).getImm();
    if (Amount != 0) {
      // We need to keep the stack aligned properly.  To do this, we round the
      // amount of space needed for the outgoing arguments up to the next
      // alignment boundary.
      Amount = (Amount+StackAlign-1)/StackAlign*StackAlign;

      MachineInstr *New = 0;
      if (Old->getOpcode() == TII.getCallFrameSetupOpcode()) {
          for (int i = 0; i<Amount; ++i) {
            New = BuildMI(MF, Old->getDebugLoc(),
                        TII.get(AVR::PUSH), AVR::R0);
            MBB.insert(I, New);
          }
      } else {
        assert(Old->getOpcode() == TII.getCallFrameDestroyOpcode());
        // factor out the amount the callee already popped.
        uint64_t CalleeAmt = Old->getOperand(1).getImm();
        Amount -= CalleeAmt;
        if (Amount)
          for (int i = 0; i<Amount; ++i) {
            New = BuildMI(MF, Old->getDebugLoc(),
                        TII.get(AVR::POP), AVR::R0);
            MBB.insert(I, New);
          }
      }

      if (New) {
        // The SRW implicit def is dead.
        //New->getOperand(3).setIsDead();
      }
    }
  } else if (I->getOpcode() == TII.getCallFrameDestroyOpcode()) {
    // If we are performing frame pointer elimination and if the callee pops
    // something off the stack pointer, add it back.
    if (uint64_t CalleeAmt = I->getOperand(1).getImm()) {
      MachineInstr *Old = I;
      MachineInstr *New = 0;
      for (int i = 0; i<CalleeAmt; ++i) {
        New = BuildMI(MF, Old->getDebugLoc(),
		      TII.get(AVR::PUSH), AVR::R0);
	      MBB.insert(I, New);
      }
      // The SRW implicit def is dead.
      //New->getOperand(3).setIsDead();
    }
  }

  MBB.erase(I);
}

void
AVRRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                        int SPAdj, RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  unsigned i = 0;
  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();
  DebugLoc dl = MI.getDebugLoc();
  while (!MI.getOperand(i).isFI()) {
    ++i;
    assert(i < MI.getNumOperands() && "Instr doesn't have FrameIndex operand!");
  }

  int FrameIndex = MI.getOperand(i).getIndex();

  unsigned BasePtr = (TFI->hasFP(MF) ? AVR::Y : AVR::SPL);
  int Offset = MF.getFrameInfo()->getObjectOffset(FrameIndex);

  // Skip the saved PC
  Offset += 2;

  if (!TFI->hasFP(MF))
    Offset += MF.getFrameInfo()->getStackSize();
  else
    Offset += 2; // Skip the saved FPW

  // Fold imm into offset
  Offset += MI.getOperand(i+1).getImm();

  /*
  if (MI.getOpcode() == AVR::ADD16ri) {
    // This is actually "load effective address" of the stack slot
    // instruction. We have only two-address instructions, thus we need to
    // expand it into mov + add

    MI.setDesc(TII.get(AVR::MOV16rr));
    MI.getOperand(i).ChangeToRegister(BasePtr, false);

    if (Offset == 0)
      return;

    // We need to materialize the offset via add instruction.
    unsigned DstReg = MI.getOperand(0).getReg();
    if (Offset < 0)
      BuildMI(MBB, llvm::next(II), dl, TII.get(AVR::SUB16ri), DstReg)
        .addReg(DstReg).addImm(-Offset);
    else
      BuildMI(MBB, llvm::next(II), dl, TII.get(AVR::ADD16ri), DstReg)
        .addReg(DstReg).addImm(Offset);

    return;
  }
  */

  MI.setDesc(TII.get(AVR::MOV8rm_INDEX));
  MI.getOperand(i).ChangeToRegister(BasePtr, false);
  MI.getOperand(i+1).ChangeToImmediate(Offset);
}

void
AVRRegisterInfo::processFunctionBeforeFrameFinalized(MachineFunction &MF)
                                                                         const {
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();

  // Create a frame entry for the FPW register that must be saved.
  if (TFI->hasFP(MF)) {
    int FrameIdx = MF.getFrameInfo()->CreateFixedObject(2, -4, true);
    (void)FrameIdx;
    assert(FrameIdx == MF.getFrameInfo()->getObjectIndexBegin() &&
           "Slot for FPW register must be last in order to be found!");
  }
}

unsigned AVRRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  /*
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();
  return TFI->hasFP(MF) ? AVR::Y : AVR::SPW;
  */

  return AVR::Y;
}
