//==- AVRFrameLowering.h - Define frame lowering for AVR --*- C++ -*--==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//
//===----------------------------------------------------------------------===//

#ifndef AVR_FRAMEINFO_H
#define AVR_FRAMEINFO_H

#include "AVR.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {
  class AVRSubtarget;

class AVRFrameLowering : public TargetFrameLowering {

public:
  explicit AVRFrameLowering()
    : TargetFrameLowering(TargetFrameLowering::StackGrowsDown, 2, -2){
  }

  /// emitProlog/emitEpilog - These methods insert prolog and epilog code into
  /// the function.
  void emitPrologue(MachineFunction &MF) const;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const;

  bool spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 const std::vector<CalleeSavedInfo> &CSI,
                                 const TargetRegisterInfo *TRI) const;
  bool restoreCalleeSavedRegisters(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MI,
                                   const std::vector<CalleeSavedInfo> &CSI,
                                   const TargetRegisterInfo *TRI) const;

  bool hasFP(const MachineFunction &MF) const;
  bool hasReservedCallFrame(const MachineFunction &MF) const;
};

} // End llvm namespace

#endif
