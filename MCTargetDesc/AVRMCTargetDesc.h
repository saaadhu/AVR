//===-- AVRMCTargetDesc.h - AVR Target Descriptions -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides AVR specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef AVRMCTARGETDESC_H
#define AVRMCTARGETDESC_H

namespace llvm {
class MCSubtargetInfo;
class Target;
class StringRef;

extern Target TheAVRTarget;

} // End llvm namespace

// Defines symbolic names for AVR registers.
// This defines a mapping from register name to register number.
#define GET_REGINFO_ENUM
#include "AVRGenRegisterInfo.inc"

// Defines symbolic names for the AVR instructions.
#define GET_INSTRINFO_ENUM
#include "AVRGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "AVRGenSubtargetInfo.inc"

#endif
