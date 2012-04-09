//======-- AVRFrameLowering.cpp - AVR Frame Information -------=========//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the AVR implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "AVRFrameLowering.h"
#include "AVRInstrInfo.h"
#include "AVRMachineFunctionInfo.h"
#include "llvm/Function.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Target/TargetData.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

// For the AVR, accessing stack slots without a stack frame is expensive, as SP is not a register
// that can be used for indirect load. Using SP as the base register will therefore involve
// a couple of INs into an indexed register followed by an indexed load or store. Doing this for
// every stack slot access is going to blow up the function size very quickly.
// So, if stack slots are needed, setup the stack frame with Y always.

bool AVRFrameLowering::hasFP(const MachineFunction &MF) const {
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  const AVRMachineFunctionInfo *AVRFI = MF.getInfo<AVRMachineFunctionInfo>();
  const uint64_t NumStackBytes = MFI->getStackSize() - AVRFI->getCalleeSavedFrameSize();

  return (MF.getTarget().Options.DisableFramePointerElim(MF) ||
          MF.getFrameInfo()->hasVarSizedObjects() ||
          MFI->isFrameAddressTaken());
}

bool AVRFrameLowering::hasReservedCallFrame(const MachineFunction &MF) const {
  return !MF.getFrameInfo()->hasVarSizedObjects();
}

void AVRFrameLowering::emitPrologue(MachineFunction &MF) const {
  
  MachineBasicBlock &MBB = MF.front();   // Prolog goes in entry BB
  MachineFrameInfo *MFI = MF.getFrameInfo();
  AVRMachineFunctionInfo *AVRFI = MF.getInfo<AVRMachineFunctionInfo>();
  const AVRInstrInfo &TII =
    *static_cast<const AVRInstrInfo*>(MF.getTarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo.
  uint64_t StackSize = MFI->getStackSize();

  // Calculate required stack adjustment
  uint64_t FrameSize = StackSize;
  uint64_t NumBytes = FrameSize - AVRFI->getCalleeSavedFrameSize();

  if (hasFP(MF)) {

    // Save FPW into the appropriate stack slot...
    BuildMI(MBB, MBBI, DL, TII.get(AVR::PUSH))
      .addReg(AVR::R28, RegState::Kill);

    BuildMI(MBB, MBBI, DL, TII.get(AVR::PUSH))
      .addReg(AVR::R29, RegState::Kill);
   }


  // Skip the callee-saved push instructions.
  while (MBBI != MBB.end() && (MBBI->getOpcode() == AVR::PUSH))
    ++MBBI;

  if (MBBI != MBB.end())
    DL = MBBI->getDebugLoc();

  // Write IN R30, SPL
  //       SBCI R30, NumBytes
  //       OUT SPL, R30

  if (NumBytes) { // adjust stack pointer: SPW -= numbytes
      MachineInstr *MI =
        BuildMI(MBB, MBBI, DL, TII.get(AVR::IN), AVR::R29)
        .addReg(AVR::SPL);
        BuildMI(MBB, MBBI, DL, TII.get(AVR::IN), AVR::R28)
        .addReg(AVR::SPH);
        BuildMI(MBB, MBBI, DL, TII.get(AVR::SUB8wri), AVR::R28)
        .addReg(AVR::R30).addImm(NumBytes);
        BuildMI(MBB, MBBI, DL, TII.get(AVR::OUT), AVR::SPL)
        .addReg(AVR::R28);
        BuildMI(MBB, MBBI, DL, TII.get(AVR::OUT), AVR::SPH)
        .addReg(AVR::R29);
      // The SRW implicit def is dead.
      //MI->getOperand(3).setIsDead();

      }

  // Set the FP register to the updated SP. Setting it at the top
  // of the stack frame allows std y+d instructions (stack grows down).
  if (hasFP(MF) || NumBytes) {

    // Mark the FramePtr as live-in in every block except the entry.
    for (MachineFunction::iterator I = llvm::next(MF.begin()), E = MF.end();
        I != E; ++I) {
      I->addLiveIn(AVR::R28);
      I->addLiveIn(AVR::R29);
    }
  }
}

void AVRFrameLowering::emitEpilogue(MachineFunction &MF,
                                       MachineBasicBlock &MBB) const {
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  AVRMachineFunctionInfo *AVRFI = MF.getInfo<AVRMachineFunctionInfo>();
  const AVRInstrInfo &TII =
    *static_cast<const AVRInstrInfo*>(MF.getTarget().getInstrInfo());

  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  unsigned RetOpcode = MBBI->getOpcode();
  DebugLoc DL = MBBI->getDebugLoc();

  switch (RetOpcode) {
  case AVR::RET:
  case AVR::RETI: break;  // These are ok
  default:
    llvm_unreachable("Can only insert epilog into returning blocks");
  }

  // Get the number of bytes to allocate from the FrameInfo
  uint64_t StackSize = MFI->getStackSize();
  unsigned CSSize = AVRFI->getCalleeSavedFrameSize();
  uint64_t FrameSize = StackSize;
  uint64_t NumBytes = FrameSize - CSSize;

  if (hasFP(MF)) {
    // Calculate required stack adjustment

    // pop FPW.
    BuildMI(MBB, MBBI, DL, TII.get(AVR::POP), AVR::R29);
    BuildMI(MBB, MBBI, DL, TII.get(AVR::POP), AVR::R28);
  }

  // Skip the callee-saved pop instructions.
  while (MBBI != MBB.begin()) {
    MachineBasicBlock::iterator PI = prior(MBBI);
    unsigned Opc = PI->getOpcode();
    if (Opc != AVR::POP && !PI->isTerminator())
      break;
    --MBBI;
  }

  DL = MBBI->getDebugLoc();

  if (MFI->hasVarSizedObjects()) {
    assert(false && "Variable sized objects not handled yet.");
  } else {
    // adjust stack pointer back: SPW += numbytes by repeatedly doing POP r0
    if (NumBytes) {
      for (uint64_t i = 0; i<NumBytes; ++i)
      {
      MachineInstr *MI =
        BuildMI(MBB, MBBI, DL, TII.get(AVR::POP))
        .addReg(AVR::R0);
      }
    }
  }
}

// FIXME: Can we eleminate these in favour of generic code?
bool
AVRFrameLowering::spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                           MachineBasicBlock::iterator MI,
                                        const std::vector<CalleeSavedInfo> &CSI,
                                        const TargetRegisterInfo *TRI) const {
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getTarget().getInstrInfo();
  AVRMachineFunctionInfo *MFI = MF.getInfo<AVRMachineFunctionInfo>();
  MFI->setCalleeSavedFrameSize(CSI.size() * 2);

  for (unsigned i = CSI.size(); i != 0; --i) {
    unsigned Reg = CSI[i-1].getReg();
    // Add the callee-saved register as live-in. It's killed at the spill.
    MBB.addLiveIn(Reg);
    BuildMI(MBB, MI, DL, TII.get(AVR::PUSH))
      .addReg(Reg, RegState::Kill);
  }
  return true;
}

bool
AVRFrameLowering::restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                                                 MachineBasicBlock::iterator MI,
                                        const std::vector<CalleeSavedInfo> &CSI,
                                        const TargetRegisterInfo *TRI) const {
  if (CSI.empty())
    return false;

  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  MachineFunction &MF = *MBB.getParent();
  const TargetInstrInfo &TII = *MF.getTarget().getInstrInfo();

  for (unsigned i = 0, e = CSI.size(); i != e; ++i)
    BuildMI(MBB, MI, DL, TII.get(AVR::POP), CSI[i].getReg());

  return true;
}
