//===-- AVRAsmPrinter.cpp - AVR LLVM assembly writer ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the AVR assembly language.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "AVR.h"
#include "AVRInstrInfo.h"
#include "AVRMCInstLower.h"
#include "AVRTargetMachine.h"
#include "InstPrinter/AVRInstPrinter.h"
#include "llvm/Constants.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Module.h"
#include "llvm/Assembly/Writer.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Target/Mangler.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

namespace {
  class AVRAsmPrinter : public AsmPrinter {
  public:
    AVRAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
      : AsmPrinter(TM, Streamer) {}

    virtual const char *getPassName() const {
      return "AVR Assembly Printer";
    }

    void printOperand(const MachineInstr *MI, int OpNum,
                      raw_ostream &O, const char* Modifier = 0);
    void printSrcMemOperand(const MachineInstr *MI, int OpNum,
                            raw_ostream &O);
    bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                         unsigned AsmVariant, const char *ExtraCode,
                         raw_ostream &O);
    bool PrintAsmMemoryOperand(const MachineInstr *MI,
                               unsigned OpNo, unsigned AsmVariant,
                               const char *ExtraCode, raw_ostream &O);
    void EmitInstruction(const MachineInstr *MI);
  };
} // end of anonymous namespace


void AVRAsmPrinter::printOperand(const MachineInstr *MI, int OpNum,
                                    raw_ostream &O, const char *Modifier) {
  const MachineOperand &MO = MI->getOperand(OpNum);
  switch (MO.getType()) {
  default: assert(0 && "Not implemented yet!");
  case MachineOperand::MO_Register:
    O << AVRInstPrinter::getRegisterName(MO.getReg());
    return;
  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    return;
  case MachineOperand::MO_MachineBasicBlock:
    O << *MO.getMBB()->getSymbol();
    return;
  case MachineOperand::MO_GlobalAddress: {
    bool isMemOp  = Modifier && !strcmp(Modifier, "mem");
    uint64_t Offset = MO.getOffset();

    // If the global address expression is a part of displacement field with a
    // register base, we should not emit any prefix symbol here, e.g.
    //   mov.w &foo, r1
    // vs
    //   mov.w glb(r1), r2
    // Otherwise (!) AVR-as will silently miscompile the output :(
    //if (!Modifier || strcmp(Modifier, "nohash"))
    //  O << (isMemOp ? '&' : '#');
    if (Offset)
      O << '(' << Offset << '+';

    O << *Mang->getSymbol(MO.getGlobal());

    if (Offset)
      O << ')';

    return;
  }
  case MachineOperand::MO_ExternalSymbol: {
    bool isMemOp  = Modifier && !strcmp(Modifier, "mem");
    //O << (isMemOp ? '&' : '#');
    O << MAI->getGlobalPrefix() << MO.getSymbolName();
    return;
  }
  }
}

void AVRAsmPrinter::printSrcMemOperand(const MachineInstr *MI, int OpNum,
                                          raw_ostream &O) {
  const MachineOperand &Base = MI->getOperand(OpNum);
  const MachineOperand &Disp = MI->getOperand(OpNum+1);

  printOperand(MI, OpNum, O);
  O << '+';
  printOperand(MI, OpNum+1, O, "nohash");

}

/// PrintAsmOperand - Print out an operand for an inline asm expression.
///
bool AVRAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                       unsigned AsmVariant,
                                       const char *ExtraCode, raw_ostream &O) {
  // Does this asm operand have a single letter operand modifier?
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  printOperand(MI, OpNo, O);
  return false;
}

bool AVRAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                             unsigned OpNo, unsigned AsmVariant,
                                             const char *ExtraCode,
                                             raw_ostream &O) {
  if (ExtraCode && ExtraCode[0]) {
    return true; // Unknown modifier.
  }
  printSrcMemOperand(MI, OpNo, O);
  return false;
}

//===----------------------------------------------------------------------===//
void AVRAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  AVRMCInstLower MCInstLowering(OutContext, *Mang, *this);

  MCInst TmpInst;
  MCInstLowering.Lower(MI, TmpInst);
  OutStreamer.EmitInstruction(TmpInst);
}

// Force static initialization.
extern "C" void LLVMInitializeAVRAsmPrinter() {
  RegisterAsmPrinter<AVRAsmPrinter> X(TheAVRTarget);
}
