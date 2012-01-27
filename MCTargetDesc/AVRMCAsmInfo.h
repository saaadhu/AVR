//=====-- AVRMCAsmInfo.h - AVR asm properties -----------*- C++ -*--====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the AVRMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef AVRTARGETASMINFO_H
#define AVRTARGETASMINFO_H

#include "llvm/ADT/StringRef.h"
#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
  class Target;

  class AVRMCAsmInfo : public MCAsmInfo {
    virtual void anchor();
  public:
    explicit AVRMCAsmInfo(const Target &T, StringRef TT);
  };

} // namespace llvm

#endif
