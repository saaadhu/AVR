//===- AVRInstrInfo.h - AVR Instruction Information -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the AVR implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TARGET_AVRINSTRINFO_H
#define LLVM_TARGET_AVRINSTRINFO_H

#include "llvm/Target/TargetInstrInfo.h"
#include "AVRRegisterInfo.h"

#define GET_INSTRINFO_HEADER
#include "AVRGenInstrInfo.inc"

namespace llvm {

class AVRTargetMachine;

/// AVRII - This namespace holds all of the target specific flags that
/// instruction info tracks.
///
namespace AVRII {
  enum {
    SizeShift   = 2,
    SizeMask    = 7 << SizeShift,

    SizeUnknown = 0 << SizeShift,
    SizeSpecial = 1 << SizeShift,
    Size2Bytes  = 2 << SizeShift,
    Size4Bytes  = 3 << SizeShift,
    Size6Bytes  = 4 << SizeShift
  };
}

class AVRInstrInfo : public AVRGenInstrInfo {
  const AVRRegisterInfo RI;
  AVRTargetMachine &TM;
public:
  explicit AVRInstrInfo(AVRTargetMachine &TM);

  /// getRegisterInfo - TargetInstrInfo is a superset of MRegister info.  As
  /// such, whenever a client has an instance of instruction info, it should
  /// always be able to get register info as well (through this method).
  ///
  virtual const TargetRegisterInfo &getRegisterInfo() const { return RI; }

  void copyPhysReg(MachineBasicBlock &MBB,
                   MachineBasicBlock::iterator I, DebugLoc DL,
                   unsigned DestReg, unsigned SrcReg,
                   bool KillSrc) const;

  virtual void storeRegToStackSlot(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MI,
                                   unsigned SrcReg, bool isKill,
                                   int FrameIndex,
                                   const TargetRegisterClass *RC,
                                   const TargetRegisterInfo *TRI) const;
  virtual void loadRegFromStackSlot(MachineBasicBlock &MBB,
                                    MachineBasicBlock::iterator MI,
                                    unsigned DestReg, int FrameIdx,
                                    const TargetRegisterClass *RC,
                                    const TargetRegisterInfo *TRI) const;

  unsigned GetInstSizeInBytes(const MachineInstr *MI) const;

  // Branch folding goodness
  bool ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const;
  bool isUnpredicatedTerminator(const MachineInstr *MI) const;
  bool AnalyzeBranch(MachineBasicBlock &MBB,
                     MachineBasicBlock *&TBB, MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify) const;

  unsigned RemoveBranch(MachineBasicBlock &MBB) const;
  unsigned InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB,
                        const SmallVectorImpl<MachineOperand> &Cond,
                        DebugLoc DL) const;

};

}

#endif
