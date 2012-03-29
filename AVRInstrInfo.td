//===- AVRInstrInfo.td - AVR Instruction defs -----------*- tblgen-*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source 
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the AVR instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "AVRInstrFormats.td"

//===----------------------------------------------------------------------===//
// Type Constraints.
//===----------------------------------------------------------------------===//
class SDTCisI8<int OpNum> : SDTCisVT<OpNum, i8>;
class SDTCisI16<int OpNum> : SDTCisVT<OpNum, i16>;

//===----------------------------------------------------------------------===//
// Type Profiles.
//===----------------------------------------------------------------------===//
def SDT_AVRCall         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_AVRCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i16>]>;
def SDT_AVRCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i16>, SDTCisVT<1, i16>]>;
def SDT_AVRWrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                                  SDTCisPtrTy<0>]>;
def SDT_AVRCmp          : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def SDT_AVRBrCC         : SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>,
                                                  SDTCisVT<1, i8>]>;
def SDT_AVRSelectCC     : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                                                  SDTCisSameAs<1, 2>, 
                                                  SDTCisVT<3, i8>]>;
def SDT_AVRShift        : SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>,
                                                  SDTCisI8<2>]>;

//===----------------------------------------------------------------------===//
// AVR Specific Node Definitions.
//===----------------------------------------------------------------------===//
def AVRretflag  : SDNode<"AVRISD::RET_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;
def AVRretiflag : SDNode<"AVRISD::RETI_FLAG", SDTNone,
                       [SDNPHasChain, SDNPOptInGlue]>;

def AVRrra     : SDNode<"AVRISD::RRA", SDTIntUnaryOp, []>;
def AVRrla     : SDNode<"AVRISD::RLA", SDTIntUnaryOp, []>;
def AVRrrc     : SDNode<"AVRISD::RRC", SDTIntUnaryOp, []>;

def AVRcall    : SDNode<"AVRISD::CALL", SDT_AVRCall,
                     [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;
def AVRcallseq_start :
                 SDNode<"ISD::CALLSEQ_START", SDT_AVRCallSeqStart,
                        [SDNPHasChain, SDNPOutGlue]>;
def AVRcallseq_end :
                 SDNode<"ISD::CALLSEQ_END",   SDT_AVRCallSeqEnd,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def AVRWrapper : SDNode<"AVRISD::Wrapper", SDT_AVRWrapper>;
def AVRcmp     : SDNode<"AVRISD::CMP", SDT_AVRCmp, [SDNPOutGlue]>;
def AVRbrcc    : SDNode<"AVRISD::BR_CC", SDT_AVRBrCC,
                            [SDNPHasChain, SDNPInGlue]>;
def AVRselectcc: SDNode<"AVRISD::SELECT_CC", SDT_AVRSelectCC,
                            [SDNPInGlue]>;
def AVRshl     : SDNode<"AVRISD::SHL", SDT_AVRShift, []>;
def AVRsra     : SDNode<"AVRISD::SRA", SDT_AVRShift, []>;
def AVRsrl     : SDNode<"AVRISD::SRL", SDT_AVRShift, []>;

//===----------------------------------------------------------------------===//
// AVR Operand Definitions.
//===----------------------------------------------------------------------===//

// Address operands
def memsrc : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

def memdst : Operand<i16> {
  let PrintMethod = "printSrcMemOperand";
  let MIOperandInfo = (ops GR16, i16imm);
}

// Short jump targets have OtherVT type and are printed as pcrel imm values.
def jmptarget : Operand<OtherVT> {
  let PrintMethod = "printPCRelImmOperand";
}

// Operand for printing out a condition code.
def cc : Operand<i8> {
  let PrintMethod = "printCCOperand";
}

//===----------------------------------------------------------------------===//
// AVR Complex Pattern Definitions.
//===----------------------------------------------------------------------===//

def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], []>;

//===----------------------------------------------------------------------===//
// Pattern Fragments
def zextloadi16i8 : PatFrag<(ops node:$ptr), (i16 (zextloadi8 node:$ptr))>;
def  extloadi16i8 : PatFrag<(ops node:$ptr), (i16 ( extloadi8 node:$ptr))>;
def and_su : PatFrag<(ops node:$lhs, node:$rhs), (and node:$lhs, node:$rhs), [{
  return N->hasOneUse();
}]>;
//===----------------------------------------------------------------------===//

// Instruction list..

// ADJCALLSTACKDOWN/UP implicitly use/def SP because they may be expanded into
// a stack adjustment and the codegen must know that they may modify the stack
// pointer before prolog-epilog rewriting occurs.
// Pessimistically assume ADJCALLSTACKDOWN / ADJCALLSTACKUP will become
// sub / add which can clobber SRW.
let Defs = [SPH, SPL], Uses = [SPH, SPL] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i16imm:$amt),
                              "#ADJCALLSTACKDOWN",
                              [(AVRcallseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i16imm:$amt1, i16imm:$amt2),
                              "#ADJCALLSTACKUP",
                              [(AVRcallseq_end timm:$amt1, timm:$amt2)]>;
}

/*

let usesCustomInserter = 1 in {
  def Select8  : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$src2, i8imm:$cc),
                        "# Select8 PSEUDO",
                        [(set GR8:$dst,
                          (AVRselectcc GR8:$src, GR8:$src2, imm:$cc))]>;
  def Select16 : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR16:$src2, i8imm:$cc),
                        "# Select16 PSEUDO",
                        [(set GR16:$dst,
                          (AVRselectcc GR16:$src, GR16:$src2, imm:$cc))]>;
  let Defs = [SRW] in {
  def Shl8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Shl8 PSEUDO",
                        [(set GR8:$dst, (AVRshl GR8:$src, GR8:$cnt))]>;
  def Shl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR8:$cnt),
                        "# Shl16 PSEUDO",
                        [(set GR16:$dst, (AVRshl GR16:$src, GR8:$cnt))]>;
  def Sra8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Sra8 PSEUDO",
                        [(set GR8:$dst, (AVRsra GR8:$src, GR8:$cnt))]>;
  def Sra16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR8:$cnt),
                        "# Sra16 PSEUDO",
                        [(set GR16:$dst, (AVRsra GR16:$src, GR8:$cnt))]>;
  def Srl8     : Pseudo<(outs GR8:$dst), (ins GR8:$src, GR8:$cnt),
                        "# Srl8 PSEUDO",
                        [(set GR8:$dst, (AVRsrl GR8:$src, GR8:$cnt))]>;
  def Srl16    : Pseudo<(outs GR16:$dst), (ins GR16:$src, GR8:$cnt),
                        "# Srl16 PSEUDO",
                        [(set GR16:$dst, (AVRsrl GR16:$src, GR8:$cnt))]>;

  }
}

*/

let neverHasSideEffects = 1 in
def NOP : Pseudo<(outs), (ins), "nop", []>;
//===----------------------------------------------------------------------===//
//  Control Flow Instructions...
//

// FIXME: Provide proper encoding!
let isReturn = 1, isTerminator = 1, isBarrier = 1 in {
  def RET  : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                     (outs), (ins), "ret",  [(AVRretflag)]>;
  def RETI : II16r<0x0, (outs), (ins), "reti", [(AVRretiflag)]>;
}

let isBranch = 1, isTerminator = 1 in {

// FIXME: expand opcode & cond field for branches!

// Direct branch
let isBarrier = 1 in {
  // Short branch
  def JMP : CJForm<0, 0, (outs), (ins jmptarget:$dst),
                   "jmp\t$dst",
                   [(br bb:$dst)]>;
  /*
  let isIndirectBranch = 1 in {
    // Long branches
    def Bi  : I16ri<0, (outs), (ins i16imm:$brdst),
                    "br\t$brdst",
                    [(brind tblockaddress:$brdst)]>;
    def Br  : I16rr<0, (outs), (ins GR16:$brdst),
                    "mov.w\t{$brdst, pc}",
                    [(brind GR16:$brdst)]>;
    def Bm  : I16rm<0, (outs), (ins memsrc:$brdst),
                    "mov.w\t{$brdst, pc}",
                    [(brind (load addr:$brdst))]>;
  }
  */
}

// Conditional branches

let Uses = [SREG] in 
  def JCC : CJForm<0, 0,
                   (outs), (ins jmptarget:$dst, cc:$cc),
                   "br$cc\t$dst",
                   [(AVRbrcc bb:$dst, imm:$cc)]>;
} // isBranch, isTerminator

//===----------------------------------------------------------------------===//
//  Call Instructions...
//
let isCall = 1 in
  // All calls clobber the non-callee saved registers. SPW is marked as
  // a use to prevent stack-pointer assignments that appear immediately
  // before calls from potentially appearing dead. Uses for argument
  // registers are added manually.
  let Defs = [R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R30, R31],
      Uses = [SPL, SPH] in {
    def CALL     : II16i<0x0,
                          (outs), (ins i16imm:$dst, variable_ops),
                          "call\t$dst", [(AVRcall imm:$dst)]>;
    /* TODO : Not yet implemented
    def ICALL    : II16r<0x0,
                          (outs), (ins GR16:$dst, variable_ops),
                          "icall", [(AVRcall GR16:$dst)]>;
    */
  }


//  IO Instructions
//
def OUT      : I8rr<0x0,
		   (outs IO8:$dst), (ins GR8:$src),
                   "out \t{$dst, $src}",
                    []>;

def IN      : I8rr<0x0,
		   (outs GR8:$dst), (ins IO8:$src),
                   "in \t{$dst, $src}",
                    []>;

//===----------------------------------------------------------------------===//
//  Miscellaneous Instructions...
//
let Defs = [SPH, SPL], Uses = [SPH, SPL], neverHasSideEffects=1 in {
let mayLoad = 1 in
def POP      : II8r<0x0,
                       (outs GR8:$reg), (ins), "pop \t$reg", []>;

let mayStore = 1 in
def PUSH  : II8r<0x0,
                     (outs), (ins GR8:$reg), "push \t$reg",[]>;
}

//===----------------------------------------------------------------------===//
// Move Instructions

// FIXME: Provide proper encoding!
let neverHasSideEffects = 1 in {
def MOV8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src),
                   "mov \t{$dst, $src}",
                   []>;
def MOV16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "movw \t{$dst, $src}",
                    []>;
}

// FIXME: Provide proper encoding!
let isReMaterializable = 1, isAsCheapAsAMove = 1 in {
def MOV8ri  : I8ri<0x0,
                   (outs IGR8:$dst), (ins i8imm:$src),
                   "ldi\t{$dst, $src}",
                   [(set IGR8:$dst, imm:$src)]>;
}

let canFoldAsLoad = 1, isReMaterializable = 1 in {
def MOV8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins memsrc:$src),
                   "lds\t{$dst, $src}",
                   [(set GR8:$dst, (load addr:$src))]>;
def MOV16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "lds\t{$dst, $src}",
                    [(set GR16:$dst, (load addr:$src))]>;
}
def MOV8rm_INDEX  : I8rm<0x0,
                   (outs GR8:$dst), (ins memsrc:$src),
                   "ldsd\t{$dst, $src}",
                   []>;
def MOV16rm_INDEX : I16rm<0x0,
                    (outs GR16:$dst), (ins memsrc:$src),
                    "lds\t{$dst, $src}",
                    []>;

/*

def MOVZX16rr8 : I8rr<0x0,
                      (outs GR16:$dst), (ins GR8:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (zext GR8:$src))]>;
def MOVZX16rm8 : I8rm<0x0,
                      (outs GR16:$dst), (ins memsrc:$src),
                      "mov.b\t{$src, $dst}",
                      [(set GR16:$dst, (zextloadi16i8 addr:$src))]>;
*/

let mayLoad = 1, hasExtraDefRegAllocReq = 1, Constraints = "$base = $base_wb" in {
def MOV8rm_POST  : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb), (ins GR16:$base),
                         "ldd\t{$dst, @$base+}", []>;
def MOV16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb), (ins GR16:$base),
                           "ldd\t{$dst, @$base+}", []>;
}

/// Any instruction that defines a 8-bit result leaves the high half of the
// register. Truncate can be lowered to EXTRACT_SUBREG, and CopyFromReg may
// be copying from a truncate, but any other 8-bit operation will zero-extend
// up to 16 bits.
def def8 : PatLeaf<(i8 GR8:$src), [{
  return N->getOpcode() != ISD::TRUNCATE &&
         N->getOpcode() != TargetOpcode::EXTRACT_SUBREG &&
         N->getOpcode() != ISD::CopyFromReg;
}]>;

// In the case of a 8-bit def that is known to implicitly zero-extend,
// we can use a SUBREG_TO_REG.
//def : Pat<(i16 (zext def8:$src)),
//          (SUBREG_TO_REG (i16 0), GR8:$src, subreg_8bit)>;


def MOV8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "sts\t{$dst, $src}",
                   [(store GR8:$src, addr:$dst)]>;
def MOV16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "sts\t{$dst, $src}",
                    [(store GR16:$src, addr:$dst)]>;

def MOV8mr_POST  : IForm8<0x0, DstMem, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb), (ins GR16:$base),
                         "std\t{$dst, @$base+}", []>;
def MOV16mr_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb), (ins GR16:$base),
                           "std\t{$dst, @$base+}", []>;

//===----------------------------------------------------------------------===//
// Arithmetic Instructions

let Constraints = "$src = $dst" in {

//let Defs = [SRW] in {

let isCommutable = 1 in { // X = ADD Y, Z  == X = ADD Z, Y

def ADD8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "add \t{$dst, $src2}",
                   [(set GR8:$dst, (add GR8:$src, GR8:$src2))
                   ]>;
}
}

/*
def ADD16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "add.w\t{$src2, $dst}",
                    [(set GR16:$dst, (add GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;

def ADD8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "add.b\t{$src2, $dst}",
                   [(set GR8:$dst, (add GR8:$src, (load addr:$src2))),
                    (implicit SRW)]>;
def ADD16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "add.w\t{$src2, $dst}",
                    [(set GR16:$dst, (add GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def ADD8rm_POST : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb),
                         (ins GR8:$src, GR16:$base),
                         "add.b\t{@$base+, $dst}", []>;
def ADD16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                          "add.w\t{@$base+, $dst}", []>;
}

def ADD8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "add.b\t{$src2, $dst}",
                   [(set GR8:$dst, (add GR8:$src, imm:$src2)),
                    (implicit SRW)]>;
def ADD16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "add.w\t{$src2, $dst}",
                    [(set GR16:$dst, (add GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

let Constraints = "" in {
def ADD8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "add.b\t{$src, $dst}",
                   [(store (add (load addr:$dst), GR8:$src), addr:$dst),
                    (implicit SRW)]>;
def ADD16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "add.w\t{$src, $dst}",
                    [(store (add (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def ADD8mi  : I8mi<0x0,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "add.b\t{$src, $dst}",
                   [(store (add (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SRW)]>;
def ADD16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "add.w\t{$src, $dst}",
                    [(store (add (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def ADD8mm  : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "add.b\t{$src, $dst}",
                   [(store (add (load addr:$dst), 
                                (i8 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
def ADD16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "add.w\t{$src, $dst}",
                    [(store (add (load addr:$dst), 
                                  (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;
}

let Uses = [SRW] in {

let isCommutable = 1 in { // X = ADDC Y, Z  == X = ADDC Z, Y
def ADC8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "addc.b\t{$src2, $dst}",
                   [(set GR8:$dst, (adde GR8:$src, GR8:$src2)),
                    (implicit SRW)]>;
def ADC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
} // isCommutable

def ADC8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "addc.b\t{$src2, $dst}",
                   [(set GR8:$dst, (adde GR8:$src, imm:$src2)),
                    (implicit SRW)]>;
def ADC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def ADC8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "addc.b\t{$src2, $dst}",
                   [(set GR8:$dst, (adde GR8:$src, (load addr:$src2))),
                    (implicit SRW)]>;
def ADC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "addc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (adde GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let Constraints = "" in {
def ADC8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "addc.b\t{$src, $dst}",
                   [(store (adde (load addr:$dst), GR8:$src), addr:$dst),
                    (implicit SRW)]>;
def ADC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def ADC8mi  : I8mi<0x0,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "addc.b\t{$src, $dst}",
                   [(store (adde (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SRW)]>;
def ADC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "addc.w\t{$src, $dst}",
                    [(store (adde (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def ADC8mm  : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "addc.b\t{$src, $dst}",
                   [(store (adde (load addr:$dst), 
                                 (i8 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
def ADC16mm : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "addc.w\t{$src, $dst}",
                   [(store (adde (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
}

} // Uses = [SRW]

let isCommutable = 1 in { // X = AND Y, Z  == X = AND Z, Y
def AND8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "and.b\t{$src2, $dst}",
                   [(set GR8:$dst, (and GR8:$src, GR8:$src2)),
                    (implicit SRW)]>;
def AND16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "and.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
}

def AND8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "and.b\t{$src2, $dst}",
                   [(set GR8:$dst, (and GR8:$src, imm:$src2)),
                    (implicit SRW)]>;
def AND16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "and.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def AND8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "and.b\t{$src2, $dst}",
                   [(set GR8:$dst, (and GR8:$src, (load addr:$src2))),
                    (implicit SRW)]>;
def AND16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "and.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def AND8rm_POST : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb),
                         (ins GR8:$src, GR16:$base),
                         "and.b\t{@$base+, $dst}", []>;
def AND16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "and.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def AND8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "and.b\t{$src, $dst}",
                   [(store (and (load addr:$dst), GR8:$src), addr:$dst),
                    (implicit SRW)]>;
def AND16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "and.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def AND8mi  : I8mi<0x0,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "and.b\t{$src, $dst}",
                   [(store (and (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SRW)]>;
def AND16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "and.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def AND8mm  : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "and.b\t{$src, $dst}",
                   [(store (and (load addr:$dst), 
                                (i8 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
def AND16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "and.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;
}

let isCommutable = 1 in { // X = OR Y, Z  == X = OR Z, Y
def OR8rr  : I8rr<0x0,
                  (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                  "bis.b\t{$src2, $dst}",
                  [(set GR8:$dst, (or GR8:$src, GR8:$src2))]>;
def OR16rr : I16rr<0x0,
                   (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                   "bis.w\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, GR16:$src2))]>;
}

def OR8ri  : I8ri<0x0,
                  (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                  "bis.b\t{$src2, $dst}",
                  [(set GR8:$dst, (or GR8:$src, imm:$src2))]>;
def OR16ri : I16ri<0x0,
                   (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                   "bis.w\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, imm:$src2))]>;

def OR8rm  : I8rm<0x0,
                  (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                  "bis.b\t{$src2, $dst}",
                  [(set GR8:$dst, (or GR8:$src, (load addr:$src2)))]>;
def OR16rm : I16rm<0x0,
                   (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                   "bis.w\t{$src2, $dst}",
                   [(set GR16:$dst, (or GR16:$src, (load addr:$src2)))]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def OR8rm_POST : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                        (outs GR8:$dst, GR16:$base_wb),
                        (ins GR8:$src, GR16:$base),
                        "bis.b\t{@$base+, $dst}", []>;
def OR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "bis.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def OR8mr  : I8mr<0x0,
                  (outs), (ins memdst:$dst, GR8:$src),
                  "bis.b\t{$src, $dst}",
                  [(store (or (load addr:$dst), GR8:$src), addr:$dst)]>;
def OR16mr : I16mr<0x0,
                   (outs), (ins memdst:$dst, GR16:$src),
                   "bis.w\t{$src, $dst}",
                   [(store (or (load addr:$dst), GR16:$src), addr:$dst)]>;

def OR8mi  : I8mi<0x0, 
                  (outs), (ins memdst:$dst, i8imm:$src),
                  "bis.b\t{$src, $dst}",
                  [(store (or (load addr:$dst), (i8 imm:$src)), addr:$dst)]>;
def OR16mi : I16mi<0x0,
                   (outs), (ins memdst:$dst, i16imm:$src),
                   "bis.w\t{$src, $dst}",
                   [(store (or (load addr:$dst), (i16 imm:$src)), addr:$dst)]>;

def OR8mm  : I8mm<0x0,
                  (outs), (ins memdst:$dst, memsrc:$src),
                  "bis.b\t{$src, $dst}",
                  [(store (or (i8 (load addr:$dst)),
                              (i8 (load addr:$src))), addr:$dst)]>;
def OR16mm : I16mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "bis.w\t{$src, $dst}",
                   [(store (or (i16 (load addr:$dst)),
                               (i16 (load addr:$src))), addr:$dst)]>;
}

// bic does not modify condition codes
def BIC8rr :  I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "bic.b\t{$src2, $dst}",
                   [(set GR8:$dst, (and GR8:$src, (not GR8:$src2)))]>;
def BIC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not GR16:$src2)))]>;

def BIC8rm :  I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "bic.b\t{$src2, $dst}",
                    [(set GR8:$dst, (and GR8:$src, (not (i8 (load addr:$src2)))))]>;
def BIC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "bic.w\t{$src2, $dst}",
                    [(set GR16:$dst, (and GR16:$src, (not (i16 (load addr:$src2)))))]>;

let Constraints = "" in {
def BIC8mr :  I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "bic.b\t{$src, $dst}",
                   [(store (and (load addr:$dst), (not GR8:$src)), addr:$dst)]>;
def BIC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst), (not GR16:$src)), addr:$dst)]>;

def BIC8mm :  I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "bic.b\t{$src, $dst}",
                   [(store (and (load addr:$dst),
                                (not (i8 (load addr:$src)))), addr:$dst)]>;
def BIC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "bic.w\t{$src, $dst}",
                    [(store (and (load addr:$dst),
                                 (not (i16 (load addr:$src)))), addr:$dst)]>;
}

let isCommutable = 1 in { // X = XOR Y, Z  == X = XOR Z, Y
def XOR8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "xor.b\t{$src2, $dst}",
                   [(set GR8:$dst, (xor GR8:$src, GR8:$src2)),
                    (implicit SRW)]>;
def XOR16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "xor.w\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
}

def XOR8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "xor.b\t{$src2, $dst}",
                   [(set GR8:$dst, (xor GR8:$src, imm:$src2)),
                    (implicit SRW)]>;
def XOR16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "xor.w\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def XOR8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "xor.b\t{$src2, $dst}",
                   [(set GR8:$dst, (xor GR8:$src, (load addr:$src2))),
                    (implicit SRW)]>;
def XOR16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "xor.w\t{$src2, $dst}",
                    [(set GR16:$dst, (xor GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def XOR8rm_POST : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb),
                         (ins GR8:$src, GR16:$base),
                         "xor.b\t{@$base+, $dst}", []>;
def XOR16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                           (outs GR16:$dst, GR16:$base_wb),
                           (ins GR16:$src, GR16:$base),
                           "xor.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def XOR8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "xor.b\t{$src, $dst}",
                   [(store (xor (load addr:$dst), GR8:$src), addr:$dst),
                    (implicit SRW)]>;
def XOR16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "xor.w\t{$src, $dst}",
                    [(store (xor (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def XOR8mi  : I8mi<0x0,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "xor.b\t{$src, $dst}",
                   [(store (xor (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SRW)]>;
def XOR16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "xor.w\t{$src, $dst}",
                    [(store (xor (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def XOR8mm  : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "xor.b\t{$src, $dst}",
                   [(store (xor (load addr:$dst), (i8 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
def XOR16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "xor.w\t{$src, $dst}",
                    [(store (xor (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;
}

*/


let Constraints = "$src = $dst" in {
def SUB8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "sbc \t{$dst, $src2}",
                   [(set GR8:$dst, (sub GR8:$src, GR8:$src2))
                   ]>;

/*
def SUB16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "sub.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sub GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;
*/

def SUB8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "sbci \t{$dst, $src2}",
                   [(set GR8:$dst, (sub GR8:$src, imm:$src2))]>;
}

/*
def SUB16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "sub.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sub GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def SUB8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "sub.b\t{$src2, $dst}",
                   [(set GR8:$dst, (sub GR8:$src, (load addr:$src2))),
                    (implicit SRW)]>;
def SUB16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "sub.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sub GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;


let mayLoad = 1, hasExtraDefRegAllocReq = 1, 
Constraints = "$base = $base_wb, $src = $dst" in {
def SUB8rm_POST : IForm8<0x0, DstReg, SrcPostInc, Size2Bytes,
                         (outs GR8:$dst, GR16:$base_wb),
                         (ins GR8:$src, GR16:$base),
                         "sub.b\t{@$base+, $dst}", []>;
def SUB16rm_POST : IForm16<0x0, DstReg, SrcPostInc, Size2Bytes,
                          (outs GR16:$dst, GR16:$base_wb),
                          (ins GR16:$src, GR16:$base),
                          "sub.w\t{@$base+, $dst}", []>;
}

let Constraints = "" in {
def SUB8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "sub.b\t{$src, $dst}",
                   [(store (sub (load addr:$dst), GR8:$src), addr:$dst),
                    (implicit SRW)]>;
def SUB16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "sub.w\t{$src, $dst}",
                    [(store (sub (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def SUB8mi  : I8mi<0x0,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "sub.b\t{$src, $dst}",
                   [(store (sub (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SRW)]>;
def SUB16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "sub.w\t{$src, $dst}",
                    [(store (sub (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def SUB8mm  : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "sub.b\t{$src, $dst}",
                   [(store (sub (load addr:$dst), 
                                (i8 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
def SUB16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "sub.w\t{$src, $dst}",
                    [(store (sub (load addr:$dst), 
                                 (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;
}

let Uses = [SRW] in {
def SBC8rr  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src, GR8:$src2),
                   "subc.b\t{$src2, $dst}",
                   [(set GR8:$dst, (sube GR8:$src, GR8:$src2)),
                    (implicit SRW)]>;
def SBC16rr : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src, GR16:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, GR16:$src2)),
                     (implicit SRW)]>;

def SBC8ri  : I8ri<0x0,
                   (outs GR8:$dst), (ins GR8:$src, i8imm:$src2),
                   "subc.b\t{$src2, $dst}",
                   [(set GR8:$dst, (sube GR8:$src, imm:$src2)),
                    (implicit SRW)]>;
def SBC16ri : I16ri<0x0,
                    (outs GR16:$dst), (ins GR16:$src, i16imm:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, imm:$src2)),
                     (implicit SRW)]>;

def SBC8rm  : I8rm<0x0,
                   (outs GR8:$dst), (ins GR8:$src, memsrc:$src2),
                   "subc.b\t{$src2, $dst}",
                   [(set GR8:$dst, (sube GR8:$src, (load addr:$src2))),
                    (implicit SRW)]>;
def SBC16rm : I16rm<0x0,
                    (outs GR16:$dst), (ins GR16:$src, memsrc:$src2),
                    "subc.w\t{$src2, $dst}",
                    [(set GR16:$dst, (sube GR16:$src, (load addr:$src2))),
                     (implicit SRW)]>;

let Constraints = "" in {
def SBC8mr  : I8mr<0x0,
                   (outs), (ins memdst:$dst, GR8:$src),
                   "subc.b\t{$src, $dst}",
                  [(store (sube (load addr:$dst), GR8:$src), addr:$dst),
                   (implicit SRW)]>;
def SBC16mr : I16mr<0x0,
                    (outs), (ins memdst:$dst, GR16:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), GR16:$src), addr:$dst),
                     (implicit SRW)]>;

def SBC8mi  : I8mi<0x0,
                   (outs), (ins memdst:$dst, i8imm:$src),
                   "subc.b\t{$src, $dst}",
                   [(store (sube (load addr:$dst), (i8 imm:$src)), addr:$dst),
                    (implicit SRW)]>;
def SBC16mi : I16mi<0x0,
                    (outs), (ins memdst:$dst, i16imm:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst), (i16 imm:$src)), addr:$dst),
                     (implicit SRW)]>;

def SBC8mm  : I8mm<0x0,
                   (outs), (ins memdst:$dst, memsrc:$src),
                   "subc.b\t{$src, $dst}",
                   [(store (sube (load addr:$dst),
                                 (i8 (load addr:$src))), addr:$dst),
                    (implicit SRW)]>;
def SBC16mm : I16mm<0x0,
                    (outs), (ins memdst:$dst, memsrc:$src),
                    "subc.w\t{$src, $dst}",
                    [(store (sube (load addr:$dst),
                            (i16 (load addr:$src))), addr:$dst),
                     (implicit SRW)]>;
}

} // Uses = [SRW]

// FIXME: memory variant!
def SAR8r1  : II8r<0x0,
                   (outs GR8:$dst), (ins GR8:$src),
                   "rra.b\t$dst",
                   [(set GR8:$dst, (AVRrra GR8:$src)),
                    (implicit SRW)]>;
def SAR16r1 : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rra.w\t$dst",
                    [(set GR16:$dst, (AVRrra GR16:$src)),
                     (implicit SRW)]>;

def SHL8r1  : I8rr<0x0,
                   (outs GR8:$dst), (ins GR8:$src),
                   "rla.b\t$dst",
                   [(set GR8:$dst, (AVRrla GR8:$src)),
                    (implicit SRW)]>;
def SHL16r1 : I16rr<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "rla.w\t$dst",
                    [(set GR16:$dst, (AVRrla GR16:$src)),
                     (implicit SRW)]>;

def SAR8r1c  : Pseudo<(outs GR8:$dst), (ins GR8:$src),
                      "clrc\n\t"
                      "rrc.b\t$dst",
                      [(set GR8:$dst, (AVRrrc GR8:$src)),
                       (implicit SRW)]>;
def SAR16r1c : Pseudo<(outs GR16:$dst), (ins GR16:$src),
                      "clrc\n\t"
                      "rrc.w\t$dst",
                      [(set GR16:$dst, (AVRrrc GR16:$src)),
                       (implicit SRW)]>;

// FIXME: Memory sext's ?
def SEXT16r : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "sxt\t$dst",
                    [(set GR16:$dst, (sext_inreg GR16:$src, i8)),
                     (implicit SRW)]>;

} // Defs = [SRW]

def ZEXT16r : I8rr<0x0,
                   (outs GR16:$dst), (ins GR16:$src),
                   "mov.b\t{$src, $dst}",
                   [(set GR16:$dst, (zext (trunc GR16:$src)))]>;

// FIXME: Memory bitswaps?
def SWPB16r : II16r<0x0,
                    (outs GR16:$dst), (ins GR16:$src),
                    "swpb\t$dst",
                    [(set GR16:$dst, (bswap GR16:$src))]>;

} // Constraints = "$src = $dst"

*/
// Integer comparisons
let Defs = [SREG] in {
def CMP8rr  : I8rr<0x0,
                   (outs), (ins GR8:$src, GR8:$src2),
                   "cp\t{$src, $src2}",
                   [(AVRcmp GR8:$src, GR8:$src2), (implicit SREG)]>;

def CMP8ri  : I8ri<0x0,
                   (outs), (ins GR8:$src, i8imm:$src2),
                   "cpi\t{$src, $src2}",
                   [(AVRcmp GR8:$src, imm:$src2), (implicit SREG)]>;
}
/*
def CMP8mi  : I8mi<0x0,
                   (outs), (ins memsrc:$src, i8imm:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(AVRcmp (load addr:$src),
                               (i8 imm:$src2)), (implicit SRW)]>;
def CMP16mi : I16mi<0x0,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "cmp.w\t{$src2, $src}",
                     [(AVRcmp (load addr:$src),
                                 (i16 imm:$src2)), (implicit SRW)]>;

def CMP8rm  : I8rm<0x0,
                   (outs), (ins GR8:$src, memsrc:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(AVRcmp GR8:$src, (load addr:$src2)), 
                    (implicit SRW)]>;
def CMP16rm : I16rm<0x0,
                    (outs), (ins GR16:$src, memsrc:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(AVRcmp GR16:$src, (load addr:$src2)),
                     (implicit SRW)]>;

def CMP8mr  : I8mr<0x0,
                   (outs), (ins memsrc:$src, GR8:$src2),
                   "cmp.b\t{$src2, $src}",
                   [(AVRcmp (load addr:$src), GR8:$src2),
                    (implicit SRW)]>;
def CMP16mr : I16mr<0x0,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "cmp.w\t{$src2, $src}",
                    [(AVRcmp (load addr:$src), GR16:$src2), 
                     (implicit SRW)]>;


// BIT TESTS, just sets condition codes
// Note that the C condition is set differently than when using CMP.
let isCommutable = 1 in {
def BIT8rr  : I8rr<0x0,
                   (outs), (ins GR8:$src, GR8:$src2),
                   "bit.b\t{$src2, $src}",
                   [(AVRcmp (and_su GR8:$src, GR8:$src2), 0),
                    (implicit SRW)]>;
def BIT16rr : I16rr<0x0,
                    (outs), (ins GR16:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(AVRcmp (and_su GR16:$src, GR16:$src2), 0),
                     (implicit SRW)]>;
}
def BIT8ri  : I8ri<0x0,
                   (outs), (ins GR8:$src, i8imm:$src2),
                   "bit.b\t{$src2, $src}",
                   [(AVRcmp (and_su GR8:$src, imm:$src2), 0),
                    (implicit SRW)]>;
def BIT16ri : I16ri<0x0,
                    (outs), (ins GR16:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(AVRcmp (and_su GR16:$src, imm:$src2), 0),
                     (implicit SRW)]>;

def BIT8rm  : I8rm<0x0,
                   (outs), (ins GR8:$src, memdst:$src2),
                   "bit.b\t{$src2, $src}",
                   [(AVRcmp (and_su GR8:$src,  (load addr:$src2)), 0),
                    (implicit SRW)]>;
def BIT16rm : I16rm<0x0,
                    (outs), (ins GR16:$src, memdst:$src2),
                    "bit.w\t{$src2, $src}",
                    [(AVRcmp (and_su GR16:$src,  (load addr:$src2)), 0),
                     (implicit SRW)]>;

def BIT8mr  : I8mr<0x0,
                  (outs), (ins memsrc:$src, GR8:$src2),
                  "bit.b\t{$src2, $src}",
                  [(AVRcmp (and_su (load addr:$src), GR8:$src2), 0),
                   (implicit SRW)]>;
def BIT16mr : I16mr<0x0,
                    (outs), (ins memsrc:$src, GR16:$src2),
                    "bit.w\t{$src2, $src}",
                    [(AVRcmp (and_su (load addr:$src), GR16:$src2), 0),
                     (implicit SRW)]>;

def BIT8mi  : I8mi<0x0,
                   (outs), (ins memsrc:$src, i8imm:$src2),
                   "bit.b\t{$src2, $src}",
                   [(AVRcmp (and_su (load addr:$src), (i8 imm:$src2)), 0),
                    (implicit SRW)]>;
def BIT16mi : I16mi<0x0,
                    (outs), (ins memsrc:$src, i16imm:$src2),
                    "bit.w\t{$src2, $src}",
                    [(AVRcmp (and_su (load addr:$src), (i16 imm:$src2)), 0),
                     (implicit SRW)]>;

def BIT8mm  : I8mm<0x0,
                   (outs), (ins memsrc:$src, memsrc:$src2),
                   "bit.b\t{$src2, $src}",
                   [(AVRcmp (and_su (i8 (load addr:$src)),
                                       (load addr:$src2)),
                                 0),
                      (implicit SRW)]>;
def BIT16mm : I16mm<0x0,
                    (outs), (ins memsrc:$src, memsrc:$src2),
                    "bit.w\t{$src2, $src}",
                    [(AVRcmp (and_su (i16 (load addr:$src)),
                                        (load addr:$src2)),
                                 0),
                     (implicit SRW)]>;
} // Defs = [SRW]

//===----------------------------------------------------------------------===//
// Non-Instruction Patterns

// extload
def : Pat<(extloadi16i8 addr:$src), (MOVZX16rm8 addr:$src)>;

// anyext
def : Pat<(i16 (anyext GR8:$src)),
          (SUBREG_TO_REG (i16 0), GR8:$src, subreg_8bit)>;

// truncs
def : Pat<(i8 (trunc GR16:$src)),
          (EXTRACT_SUBREG GR16:$src, subreg_8bit)>;

// GlobalAddress, ExternalSymbol
def : Pat<(i16 (AVRWrapper tglobaladdr:$dst)), (MOV16ri tglobaladdr:$dst)>;
def : Pat<(i16 (AVRWrapper texternalsym:$dst)), (MOV16ri texternalsym:$dst)>;
def : Pat<(i16 (AVRWrapper tblockaddress:$dst)), (MOV16ri tblockaddress:$dst)>;

def : Pat<(add GR16:$src, (AVRWrapper tglobaladdr :$src2)),
          (ADD16ri GR16:$src, tglobaladdr:$src2)>;
def : Pat<(add GR16:$src, (AVRWrapper texternalsym:$src2)),
          (ADD16ri GR16:$src, texternalsym:$src2)>;
def : Pat<(add GR16:$src, (AVRWrapper tblockaddress:$src2)),
          (ADD16ri GR16:$src, tblockaddress:$src2)>;

def : Pat<(store (i16 (AVRWrapper tglobaladdr:$src)), addr:$dst),
          (MOV16mi addr:$dst, tglobaladdr:$src)>;
def : Pat<(store (i16 (AVRWrapper texternalsym:$src)), addr:$dst),
          (MOV16mi addr:$dst, texternalsym:$src)>;
def : Pat<(store (i16 (AVRWrapper tblockaddress:$src)), addr:$dst),
          (MOV16mi addr:$dst, tblockaddress:$src)>;
*/

// calls
def : Pat<(AVRcall (i16 tglobaladdr:$dst)),
          (CALL tglobaladdr:$dst)>;
def : Pat<(AVRcall (i16 texternalsym:$dst)),
          (CALL texternalsym:$dst)>;

/*
// add and sub always produce carry
def : Pat<(addc GR16:$src, GR16:$src2),
          (ADD16rr GR16:$src, GR16:$src2)>;
def : Pat<(addc GR16:$src, (load addr:$src2)),
          (ADD16rm GR16:$src, addr:$src2)>;
def : Pat<(addc GR16:$src, imm:$src2),
          (ADD16ri GR16:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR16:$src), addr:$dst),
          (ADD16mr addr:$dst, GR16:$src)>;
def : Pat<(store (addc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (ADD16mm addr:$dst, addr:$src)>;

def : Pat<(addc GR8:$src, GR8:$src2),
          (ADD8rr GR8:$src, GR8:$src2)>;
def : Pat<(addc GR8:$src, (load addr:$src2)),
          (ADD8rm GR8:$src, addr:$src2)>;
def : Pat<(addc GR8:$src, imm:$src2),
          (ADD8ri GR8:$src, imm:$src2)>;
def : Pat<(store (addc (load addr:$dst), GR8:$src), addr:$dst),
          (ADD8mr addr:$dst, GR8:$src)>;
def : Pat<(store (addc (load addr:$dst), (i8 (load addr:$src))), addr:$dst),
          (ADD8mm addr:$dst, addr:$src)>;

def : Pat<(subc GR16:$src, GR16:$src2),
          (SUB16rr GR16:$src, GR16:$src2)>;
def : Pat<(subc GR16:$src, (load addr:$src2)),
          (SUB16rm GR16:$src, addr:$src2)>;
def : Pat<(subc GR16:$src, imm:$src2),
          (SUB16ri GR16:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR16:$src), addr:$dst),
          (SUB16mr addr:$dst, GR16:$src)>;
def : Pat<(store (subc (load addr:$dst), (i16 (load addr:$src))), addr:$dst),
          (SUB16mm addr:$dst, addr:$src)>;

def : Pat<(subc GR8:$src, GR8:$src2),
          (SUB8rr GR8:$src, GR8:$src2)>;
def : Pat<(subc GR8:$src, (load addr:$src2)),
          (SUB8rm GR8:$src, addr:$src2)>;
def : Pat<(subc GR8:$src, imm:$src2),
          (SUB8ri GR8:$src, imm:$src2)>;
def : Pat<(store (subc (load addr:$dst), GR8:$src), addr:$dst),
          (SUB8mr addr:$dst, GR8:$src)>;
def : Pat<(store (subc (load addr:$dst), (i8 (load addr:$src))), addr:$dst),
          (SUB8mm addr:$dst, addr:$src)>;

// peephole patterns
def : Pat<(and GR16:$src, 255), (ZEXT16r GR16:$src)>;
def : Pat<(AVRcmp (trunc (and_su GR16:$src, GR16:$src2)), 0),
          (BIT8rr (EXTRACT_SUBREG GR16:$src, subreg_8bit),
                  (EXTRACT_SUBREG GR16:$src2, subreg_8bit))>;
*/
