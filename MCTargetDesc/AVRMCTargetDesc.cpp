//===-- AVRMCTargetDesc.cpp - AVR Target Descriptions -----*- C++ -*-===//
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

#include "AVRMCTargetDesc.h"
#include "AVRMCAsmInfo.h"
#include "InstPrinter/AVRInstPrinter.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_REGINFO_MC_DESC
#include "AVRGenRegisterInfo.inc"
using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "AVRGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "AVRGenSubtargetInfo.inc"



static MCInstrInfo *createAVRMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitAVRMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createAVRMCRegisterInfo(StringRef TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitAVRMCRegisterInfo(X, AVR::PC);
  return X;
}


static MCSubtargetInfo *createAVRMCSubtargetInfo(StringRef TT, StringRef CPU,
                                                    StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitAVRMCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCCodeGenInfo *createAVRCCodeGenInfo(StringRef TT, Reloc::Model RM,
                                                CodeModel::Model CM,
                                                CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCInstPrinter *createAVRMCInstPrinter(const Target &T,
                                                unsigned SyntaxVariant,
                                                const MCAsmInfo &MAI,
                                                const MCSubtargetInfo &STI) {
    return new AVRInstPrinter(MAI);
}

extern "C" void LLVMInitializeAVRTargetMC() {
  //  Register the MC asm info.
  RegisterMCAsmInfo<AVRMCAsmInfo> X(TheAVRTarget);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheAVRTarget,
                                        createAVRCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheAVRTarget, createAVRMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheAVRTarget,
                                     createAVRMCRegisterInfo);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheAVRTarget, createAVRMCSubtargetInfo);

  // Register the MCInstPrinter.
  TargetRegistry::RegisterMCInstPrinter(TheAVRTarget, createAVRMCInstPrinter);
}
