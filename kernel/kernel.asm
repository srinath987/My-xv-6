
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	bc013103          	ld	sp,-1088(sp) # 80008bc0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	bd070713          	addi	a4,a4,-1072 # 80008c20 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	2ce78793          	addi	a5,a5,718 # 80006330 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb96f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f7878793          	addi	a5,a5,-136 # 80001024 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	748080e7          	jalr	1864(ra) # 80002872 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	bd650513          	addi	a0,a0,-1066 # 80010d60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	bf0080e7          	jalr	-1040(ra) # 80000d82 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	bc648493          	addi	s1,s1,-1082 # 80010d60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	c5690913          	addi	s2,s2,-938 # 80010df8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9c2080e7          	jalr	-1598(ra) # 80001b82 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4f4080e7          	jalr	1268(ra) # 800026bc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	0e6080e7          	jalr	230(ra) # 800022bc <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	60a080e7          	jalr	1546(ra) # 8000281c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	b3a50513          	addi	a0,a0,-1222 # 80010d60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	c08080e7          	jalr	-1016(ra) # 80000e36 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	b2450513          	addi	a0,a0,-1244 # 80010d60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bf2080e7          	jalr	-1038(ra) # 80000e36 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	b8f72323          	sw	a5,-1146(a4) # 80010df8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a9450513          	addi	a0,a0,-1388 # 80010d60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	aae080e7          	jalr	-1362(ra) # 80000d82 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	5d6080e7          	jalr	1494(ra) # 800028c8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	a6650513          	addi	a0,a0,-1434 # 80010d60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b34080e7          	jalr	-1228(ra) # 80000e36 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	a4270713          	addi	a4,a4,-1470 # 80010d60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	a1878793          	addi	a5,a5,-1512 # 80010d60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a827a783          	lw	a5,-1406(a5) # 80010df8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	9d670713          	addi	a4,a4,-1578 # 80010d60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	9c648493          	addi	s1,s1,-1594 # 80010d60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	98a70713          	addi	a4,a4,-1654 # 80010d60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	a0f72a23          	sw	a5,-1516(a4) # 80010e00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	94e78793          	addi	a5,a5,-1714 # 80010d60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	9cc7a323          	sw	a2,-1594(a5) # 80010dfc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	9ba50513          	addi	a0,a0,-1606 # 80010df8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	026080e7          	jalr	38(ra) # 8000246c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	90050513          	addi	a0,a0,-1792 # 80010d60 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	88a080e7          	jalr	-1910(ra) # 80000cf2 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	88078793          	addi	a5,a5,-1920 # 80241cf8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8c07aa23          	sw	zero,-1836(a5) # 80010e20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b8250513          	addi	a0,a0,-1150 # 800080f0 <digits+0xb0>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	66f72023          	sw	a5,1632(a4) # 80008be0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	864dad83          	lw	s11,-1948(s11) # 80010e20 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	80e50513          	addi	a0,a0,-2034 # 80010e08 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	780080e7          	jalr	1920(ra) # 80000d82 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	6b050513          	addi	a0,a0,1712 # 80010e08 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	6d6080e7          	jalr	1750(ra) # 80000e36 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	69448493          	addi	s1,s1,1684 # 80010e08 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	56c080e7          	jalr	1388(ra) # 80000cf2 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	65450513          	addi	a0,a0,1620 # 80010e28 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	516080e7          	jalr	1302(ra) # 80000cf2 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	53e080e7          	jalr	1342(ra) # 80000d36 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	3e07a783          	lw	a5,992(a5) # 80008be0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	5b0080e7          	jalr	1456(ra) # 80000dd6 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	3b07b783          	ld	a5,944(a5) # 80008be8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	3b073703          	ld	a4,944(a4) # 80008bf0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	5c6a0a13          	addi	s4,s4,1478 # 80010e28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	37e48493          	addi	s1,s1,894 # 80008be8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	37e98993          	addi	s3,s3,894 # 80008bf0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	bd8080e7          	jalr	-1064(ra) # 8000246c <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	55850513          	addi	a0,a0,1368 # 80010e28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	4aa080e7          	jalr	1194(ra) # 80000d82 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	3007a783          	lw	a5,768(a5) # 80008be0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	30673703          	ld	a4,774(a4) # 80008bf0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2f67b783          	ld	a5,758(a5) # 80008be8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	52a98993          	addi	s3,s3,1322 # 80010e28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	2e248493          	addi	s1,s1,738 # 80008be8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	2e290913          	addi	s2,s2,738 # 80008bf0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	99e080e7          	jalr	-1634(ra) # 800022bc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	4f448493          	addi	s1,s1,1268 # 80010e28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	2ae7b423          	sd	a4,680(a5) # 80008bf0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	4dc080e7          	jalr	1244(ra) # 80000e36 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	46e48493          	addi	s1,s1,1134 # 80010e28 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	3be080e7          	jalr	958(ra) # 80000d82 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	460080e7          	jalr	1120(ra) # 80000e36 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <increase_paref>:
    kfree(p);
  }
}

void increase_paref(uint64 pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	1000                	addi	s0,sp,32
    800009f2:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    800009f4:	00010517          	auipc	a0,0x10
    800009f8:	46c50513          	addi	a0,a0,1132 # 80010e60 <kmem>
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	386080e7          	jalr	902(ra) # 80000d82 <acquire>
  int pn = pa / PGSIZE;
  if (pa > PHYSTOP)
    80000a04:	4745                	li	a4,17
    80000a06:	076e                	slli	a4,a4,0x1b
    80000a08:	02976b63          	bltu	a4,s1,80000a3e <increase_paref+0x56>
    80000a0c:	00c4d793          	srli	a5,s1,0xc
    80000a10:	2781                	sext.w	a5,a5
  {
    panic("Physical Address limit exceeded");
  }
  paref[pn]++;
    80000a12:	078a                	slli	a5,a5,0x2
    80000a14:	00010717          	auipc	a4,0x10
    80000a18:	46c70713          	addi	a4,a4,1132 # 80010e80 <paref>
    80000a1c:	97ba                	add	a5,a5,a4
    80000a1e:	4398                	lw	a4,0(a5)
    80000a20:	2705                	addiw	a4,a4,1
    80000a22:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a24:	00010517          	auipc	a0,0x10
    80000a28:	43c50513          	addi	a0,a0,1084 # 80010e60 <kmem>
    80000a2c:	00000097          	auipc	ra,0x0
    80000a30:	40a080e7          	jalr	1034(ra) # 80000e36 <release>
}
    80000a34:	60e2                	ld	ra,24(sp)
    80000a36:	6442                	ld	s0,16(sp)
    80000a38:	64a2                	ld	s1,8(sp)
    80000a3a:	6105                	addi	sp,sp,32
    80000a3c:	8082                	ret
    panic("Physical Address limit exceeded");
    80000a3e:	00007517          	auipc	a0,0x7
    80000a42:	62250513          	addi	a0,a0,1570 # 80008060 <digits+0x20>
    80000a46:	00000097          	auipc	ra,0x0
    80000a4a:	afa080e7          	jalr	-1286(ra) # 80000540 <panic>

0000000080000a4e <decrease_paref>:

void decrease_paref(uint64 pa)
{
    80000a4e:	1101                	addi	sp,sp,-32
    80000a50:	ec06                	sd	ra,24(sp)
    80000a52:	e822                	sd	s0,16(sp)
    80000a54:	e426                	sd	s1,8(sp)
    80000a56:	1000                	addi	s0,sp,32
    80000a58:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    80000a5a:	00010517          	auipc	a0,0x10
    80000a5e:	40650513          	addi	a0,a0,1030 # 80010e60 <kmem>
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	320080e7          	jalr	800(ra) # 80000d82 <acquire>
  int pn = pa / PGSIZE;
  if (pa > PHYSTOP)
    80000a6a:	4745                	li	a4,17
    80000a6c:	076e                	slli	a4,a4,0x1b
    80000a6e:	02976b63          	bltu	a4,s1,80000aa4 <decrease_paref+0x56>
    80000a72:	00c4d793          	srli	a5,s1,0xc
    80000a76:	2781                	sext.w	a5,a5
  {
    panic("Physical Address limit exceeded");
  }
  paref[pn]--;
    80000a78:	078a                	slli	a5,a5,0x2
    80000a7a:	00010717          	auipc	a4,0x10
    80000a7e:	40670713          	addi	a4,a4,1030 # 80010e80 <paref>
    80000a82:	97ba                	add	a5,a5,a4
    80000a84:	4398                	lw	a4,0(a5)
    80000a86:	377d                	addiw	a4,a4,-1
    80000a88:	c398                	sw	a4,0(a5)
  release(&kmem.lock);
    80000a8a:	00010517          	auipc	a0,0x10
    80000a8e:	3d650513          	addi	a0,a0,982 # 80010e60 <kmem>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	3a4080e7          	jalr	932(ra) # 80000e36 <release>
}
    80000a9a:	60e2                	ld	ra,24(sp)
    80000a9c:	6442                	ld	s0,16(sp)
    80000a9e:	64a2                	ld	s1,8(sp)
    80000aa0:	6105                	addi	sp,sp,32
    80000aa2:	8082                	ret
    panic("Physical Address limit exceeded");
    80000aa4:	00007517          	auipc	a0,0x7
    80000aa8:	5bc50513          	addi	a0,a0,1468 # 80008060 <digits+0x20>
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	a94080e7          	jalr	-1388(ra) # 80000540 <panic>

0000000080000ab4 <kfree>:
//   kmem.freelist = r;
//   release(&kmem.lock);
// }

void kfree(void *pa)
{
    80000ab4:	1101                	addi	sp,sp,-32
    80000ab6:	ec06                	sd	ra,24(sp)
    80000ab8:	e822                	sd	s0,16(sp)
    80000aba:	e426                	sd	s1,8(sp)
    80000abc:	e04a                	sd	s2,0(sp)
    80000abe:	1000                	addi	s0,sp,32
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000ac0:	03451793          	slli	a5,a0,0x34
    80000ac4:	e3d5                	bnez	a5,80000b68 <kfree+0xb4>
    80000ac6:	84aa                	mv	s1,a0
    80000ac8:	00242797          	auipc	a5,0x242
    80000acc:	3c878793          	addi	a5,a5,968 # 80242e90 <end>
    80000ad0:	08f56c63          	bltu	a0,a5,80000b68 <kfree+0xb4>
    80000ad4:	47c5                	li	a5,17
    80000ad6:	07ee                	slli	a5,a5,0x1b
    80000ad8:	08f57863          	bgeu	a0,a5,80000b68 <kfree+0xb4>
    panic("kfree");

  r = (struct run *)pa;

  acquire(&kmem.lock);
    80000adc:	00010517          	auipc	a0,0x10
    80000ae0:	38450513          	addi	a0,a0,900 # 80010e60 <kmem>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	29e080e7          	jalr	670(ra) # 80000d82 <acquire>
  int pn = (uint64)r / PGSIZE;
    80000aec:	00c4d793          	srli	a5,s1,0xc
    80000af0:	2781                	sext.w	a5,a5
  if (paref[pn] <= 0)
    80000af2:	00279693          	slli	a3,a5,0x2
    80000af6:	00010717          	auipc	a4,0x10
    80000afa:	38a70713          	addi	a4,a4,906 # 80010e80 <paref>
    80000afe:	9736                	add	a4,a4,a3
    80000b00:	4318                	lw	a4,0(a4)
    80000b02:	06e05b63          	blez	a4,80000b78 <kfree+0xc4>
  {
    release(&kmem.lock);
    panic("check");
    // return;
  }
  paref[pn]--;
    80000b06:	377d                	addiw	a4,a4,-1
    80000b08:	0007061b          	sext.w	a2,a4
    80000b0c:	078a                	slli	a5,a5,0x2
    80000b0e:	00010697          	auipc	a3,0x10
    80000b12:	37268693          	addi	a3,a3,882 # 80010e80 <paref>
    80000b16:	97b6                	add	a5,a5,a3
    80000b18:	c398                	sw	a4,0(a5)
  if (paref[pn] > 0)
    80000b1a:	06c04f63          	bgtz	a2,80000b98 <kfree+0xe4>
  {
    release(&kmem.lock);
    return;
  }
  release(&kmem.lock);
    80000b1e:	00010917          	auipc	s2,0x10
    80000b22:	34290913          	addi	s2,s2,834 # 80010e60 <kmem>
    80000b26:	854a                	mv	a0,s2
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	30e080e7          	jalr	782(ra) # 80000e36 <release>

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000b30:	6605                	lui	a2,0x1
    80000b32:	4585                	li	a1,1
    80000b34:	8526                	mv	a0,s1
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	348080e7          	jalr	840(ra) # 80000e7e <memset>

  d = (struct run *)pa;

  acquire(&kmem.lock);
    80000b3e:	854a                	mv	a0,s2
    80000b40:	00000097          	auipc	ra,0x0
    80000b44:	242080e7          	jalr	578(ra) # 80000d82 <acquire>
  d->next = kmem.freelist;
    80000b48:	01893783          	ld	a5,24(s2)
    80000b4c:	e09c                	sd	a5,0(s1)
  kmem.freelist = d;
    80000b4e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b52:	854a                	mv	a0,s2
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	2e2080e7          	jalr	738(ra) # 80000e36 <release>
}
    80000b5c:	60e2                	ld	ra,24(sp)
    80000b5e:	6442                	ld	s0,16(sp)
    80000b60:	64a2                	ld	s1,8(sp)
    80000b62:	6902                	ld	s2,0(sp)
    80000b64:	6105                	addi	sp,sp,32
    80000b66:	8082                	ret
    panic("kfree");
    80000b68:	00007517          	auipc	a0,0x7
    80000b6c:	51850513          	addi	a0,a0,1304 # 80008080 <digits+0x40>
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	9d0080e7          	jalr	-1584(ra) # 80000540 <panic>
    release(&kmem.lock);
    80000b78:	00010517          	auipc	a0,0x10
    80000b7c:	2e850513          	addi	a0,a0,744 # 80010e60 <kmem>
    80000b80:	00000097          	auipc	ra,0x0
    80000b84:	2b6080e7          	jalr	694(ra) # 80000e36 <release>
    panic("check");
    80000b88:	00007517          	auipc	a0,0x7
    80000b8c:	50050513          	addi	a0,a0,1280 # 80008088 <digits+0x48>
    80000b90:	00000097          	auipc	ra,0x0
    80000b94:	9b0080e7          	jalr	-1616(ra) # 80000540 <panic>
    release(&kmem.lock);
    80000b98:	00010517          	auipc	a0,0x10
    80000b9c:	2c850513          	addi	a0,a0,712 # 80010e60 <kmem>
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	296080e7          	jalr	662(ra) # 80000e36 <release>
    return;
    80000ba8:	bf55                	j	80000b5c <kfree+0xa8>

0000000080000baa <freerange>:
{
    80000baa:	7139                	addi	sp,sp,-64
    80000bac:	fc06                	sd	ra,56(sp)
    80000bae:	f822                	sd	s0,48(sp)
    80000bb0:	f426                	sd	s1,40(sp)
    80000bb2:	f04a                	sd	s2,32(sp)
    80000bb4:	ec4e                	sd	s3,24(sp)
    80000bb6:	e852                	sd	s4,16(sp)
    80000bb8:	e456                	sd	s5,8(sp)
    80000bba:	e05a                	sd	s6,0(sp)
    80000bbc:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000bbe:	6785                	lui	a5,0x1
    80000bc0:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000bc4:	953a                	add	a0,a0,a4
    80000bc6:	777d                	lui	a4,0xfffff
    80000bc8:	00e574b3          	and	s1,a0,a4
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bcc:	97a6                	add	a5,a5,s1
    80000bce:	02f5eb63          	bltu	a1,a5,80000c04 <freerange+0x5a>
    80000bd2:	892e                	mv	s2,a1
    paref[pn] = 1;
    80000bd4:	00010b17          	auipc	s6,0x10
    80000bd8:	2acb0b13          	addi	s6,s6,684 # 80010e80 <paref>
    80000bdc:	4a85                	li	s5,1
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bde:	6a05                	lui	s4,0x1
    80000be0:	6989                	lui	s3,0x2
    pn = (uint64)p / PGSIZE;
    80000be2:	00c4d793          	srli	a5,s1,0xc
    paref[pn] = 1;
    80000be6:	2781                	sext.w	a5,a5
    80000be8:	078a                	slli	a5,a5,0x2
    80000bea:	97da                	add	a5,a5,s6
    80000bec:	0157a023          	sw	s5,0(a5)
    kfree(p);
    80000bf0:	8526                	mv	a0,s1
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	ec2080e7          	jalr	-318(ra) # 80000ab4 <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bfa:	87a6                	mv	a5,s1
    80000bfc:	94d2                	add	s1,s1,s4
    80000bfe:	97ce                	add	a5,a5,s3
    80000c00:	fef971e3          	bgeu	s2,a5,80000be2 <freerange+0x38>
}
    80000c04:	70e2                	ld	ra,56(sp)
    80000c06:	7442                	ld	s0,48(sp)
    80000c08:	74a2                	ld	s1,40(sp)
    80000c0a:	7902                	ld	s2,32(sp)
    80000c0c:	69e2                	ld	s3,24(sp)
    80000c0e:	6a42                	ld	s4,16(sp)
    80000c10:	6aa2                	ld	s5,8(sp)
    80000c12:	6b02                	ld	s6,0(sp)
    80000c14:	6121                	addi	sp,sp,64
    80000c16:	8082                	ret

0000000080000c18 <kinit>:
{
    80000c18:	1141                	addi	sp,sp,-16
    80000c1a:	e406                	sd	ra,8(sp)
    80000c1c:	e022                	sd	s0,0(sp)
    80000c1e:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000c20:	00007597          	auipc	a1,0x7
    80000c24:	47058593          	addi	a1,a1,1136 # 80008090 <digits+0x50>
    80000c28:	00010517          	auipc	a0,0x10
    80000c2c:	23850513          	addi	a0,a0,568 # 80010e60 <kmem>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	0c2080e7          	jalr	194(ra) # 80000cf2 <initlock>
  freerange(end, (void *)PHYSTOP);
    80000c38:	45c5                	li	a1,17
    80000c3a:	05ee                	slli	a1,a1,0x1b
    80000c3c:	00242517          	auipc	a0,0x242
    80000c40:	25450513          	addi	a0,a0,596 # 80242e90 <end>
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	f66080e7          	jalr	-154(ra) # 80000baa <freerange>
}
    80000c4c:	60a2                	ld	ra,8(sp)
    80000c4e:	6402                	ld	s0,0(sp)
    80000c50:	0141                	addi	sp,sp,16
    80000c52:	8082                	ret

0000000080000c54 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c54:	1101                	addi	sp,sp,-32
    80000c56:	ec06                	sd	ra,24(sp)
    80000c58:	e822                	sd	s0,16(sp)
    80000c5a:	e426                	sd	s1,8(sp)
    80000c5c:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c5e:	00010497          	auipc	s1,0x10
    80000c62:	20248493          	addi	s1,s1,514 # 80010e60 <kmem>
    80000c66:	8526                	mv	a0,s1
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	11a080e7          	jalr	282(ra) # 80000d82 <acquire>
  r = kmem.freelist;
    80000c70:	6c84                	ld	s1,24(s1)
  if (r)
    80000c72:	c4bd                	beqz	s1,80000ce0 <kalloc+0x8c>
  {
    int pn = (uint64)r / PGSIZE;
    80000c74:	00c4d793          	srli	a5,s1,0xc
    80000c78:	2781                	sext.w	a5,a5
    if (paref[pn] > 0)
    80000c7a:	00279693          	slli	a3,a5,0x2
    80000c7e:	00010717          	auipc	a4,0x10
    80000c82:	20270713          	addi	a4,a4,514 # 80010e80 <paref>
    80000c86:	9736                	add	a4,a4,a3
    80000c88:	4318                	lw	a4,0(a4)
    80000c8a:	04e04163          	bgtz	a4,80000ccc <kalloc+0x78>
    {
      release(&kmem.lock);
      return 0;
    }
    paref[pn] = 1;
    80000c8e:	078a                	slli	a5,a5,0x2
    80000c90:	00010717          	auipc	a4,0x10
    80000c94:	1f070713          	addi	a4,a4,496 # 80010e80 <paref>
    80000c98:	97ba                	add	a5,a5,a4
    80000c9a:	4705                	li	a4,1
    80000c9c:	c398                	sw	a4,0(a5)
    kmem.freelist = r->next;
    80000c9e:	609c                	ld	a5,0(s1)
    80000ca0:	00010517          	auipc	a0,0x10
    80000ca4:	1c050513          	addi	a0,a0,448 # 80010e60 <kmem>
    80000ca8:	ed1c                	sd	a5,24(a0)
  }
  release(&kmem.lock);
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	18c080e7          	jalr	396(ra) # 80000e36 <release>

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000cb2:	6605                	lui	a2,0x1
    80000cb4:	4595                	li	a1,5
    80000cb6:	8526                	mv	a0,s1
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	1c6080e7          	jalr	454(ra) # 80000e7e <memset>
  return (void *)r;
}
    80000cc0:	8526                	mv	a0,s1
    80000cc2:	60e2                	ld	ra,24(sp)
    80000cc4:	6442                	ld	s0,16(sp)
    80000cc6:	64a2                	ld	s1,8(sp)
    80000cc8:	6105                	addi	sp,sp,32
    80000cca:	8082                	ret
      release(&kmem.lock);
    80000ccc:	00010517          	auipc	a0,0x10
    80000cd0:	19450513          	addi	a0,a0,404 # 80010e60 <kmem>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	162080e7          	jalr	354(ra) # 80000e36 <release>
      return 0;
    80000cdc:	4481                	li	s1,0
    80000cde:	b7cd                	j	80000cc0 <kalloc+0x6c>
  release(&kmem.lock);
    80000ce0:	00010517          	auipc	a0,0x10
    80000ce4:	18050513          	addi	a0,a0,384 # 80010e60 <kmem>
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	14e080e7          	jalr	334(ra) # 80000e36 <release>
  if (r)
    80000cf0:	bfc1                	j	80000cc0 <kalloc+0x6c>

0000000080000cf2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cf2:	1141                	addi	sp,sp,-16
    80000cf4:	e422                	sd	s0,8(sp)
    80000cf6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cf8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cfa:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cfe:	00053823          	sd	zero,16(a0)
}
    80000d02:	6422                	ld	s0,8(sp)
    80000d04:	0141                	addi	sp,sp,16
    80000d06:	8082                	ret

0000000080000d08 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d08:	411c                	lw	a5,0(a0)
    80000d0a:	e399                	bnez	a5,80000d10 <holding+0x8>
    80000d0c:	4501                	li	a0,0
  return r;
}
    80000d0e:	8082                	ret
{
    80000d10:	1101                	addi	sp,sp,-32
    80000d12:	ec06                	sd	ra,24(sp)
    80000d14:	e822                	sd	s0,16(sp)
    80000d16:	e426                	sd	s1,8(sp)
    80000d18:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d1a:	6904                	ld	s1,16(a0)
    80000d1c:	00001097          	auipc	ra,0x1
    80000d20:	e4a080e7          	jalr	-438(ra) # 80001b66 <mycpu>
    80000d24:	40a48533          	sub	a0,s1,a0
    80000d28:	00153513          	seqz	a0,a0
}
    80000d2c:	60e2                	ld	ra,24(sp)
    80000d2e:	6442                	ld	s0,16(sp)
    80000d30:	64a2                	ld	s1,8(sp)
    80000d32:	6105                	addi	sp,sp,32
    80000d34:	8082                	ret

0000000080000d36 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d36:	1101                	addi	sp,sp,-32
    80000d38:	ec06                	sd	ra,24(sp)
    80000d3a:	e822                	sd	s0,16(sp)
    80000d3c:	e426                	sd	s1,8(sp)
    80000d3e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d40:	100024f3          	csrr	s1,sstatus
    80000d44:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d48:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d4a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d4e:	00001097          	auipc	ra,0x1
    80000d52:	e18080e7          	jalr	-488(ra) # 80001b66 <mycpu>
    80000d56:	5d3c                	lw	a5,120(a0)
    80000d58:	cf89                	beqz	a5,80000d72 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d5a:	00001097          	auipc	ra,0x1
    80000d5e:	e0c080e7          	jalr	-500(ra) # 80001b66 <mycpu>
    80000d62:	5d3c                	lw	a5,120(a0)
    80000d64:	2785                	addiw	a5,a5,1
    80000d66:	dd3c                	sw	a5,120(a0)
}
    80000d68:	60e2                	ld	ra,24(sp)
    80000d6a:	6442                	ld	s0,16(sp)
    80000d6c:	64a2                	ld	s1,8(sp)
    80000d6e:	6105                	addi	sp,sp,32
    80000d70:	8082                	ret
    mycpu()->intena = old;
    80000d72:	00001097          	auipc	ra,0x1
    80000d76:	df4080e7          	jalr	-524(ra) # 80001b66 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d7a:	8085                	srli	s1,s1,0x1
    80000d7c:	8885                	andi	s1,s1,1
    80000d7e:	dd64                	sw	s1,124(a0)
    80000d80:	bfe9                	j	80000d5a <push_off+0x24>

0000000080000d82 <acquire>:
{
    80000d82:	1101                	addi	sp,sp,-32
    80000d84:	ec06                	sd	ra,24(sp)
    80000d86:	e822                	sd	s0,16(sp)
    80000d88:	e426                	sd	s1,8(sp)
    80000d8a:	1000                	addi	s0,sp,32
    80000d8c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	fa8080e7          	jalr	-88(ra) # 80000d36 <push_off>
  if(holding(lk))
    80000d96:	8526                	mv	a0,s1
    80000d98:	00000097          	auipc	ra,0x0
    80000d9c:	f70080e7          	jalr	-144(ra) # 80000d08 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da0:	4705                	li	a4,1
  if(holding(lk))
    80000da2:	e115                	bnez	a0,80000dc6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da4:	87ba                	mv	a5,a4
    80000da6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000daa:	2781                	sext.w	a5,a5
    80000dac:	ffe5                	bnez	a5,80000da4 <acquire+0x22>
  __sync_synchronize();
    80000dae:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000db2:	00001097          	auipc	ra,0x1
    80000db6:	db4080e7          	jalr	-588(ra) # 80001b66 <mycpu>
    80000dba:	e888                	sd	a0,16(s1)
}
    80000dbc:	60e2                	ld	ra,24(sp)
    80000dbe:	6442                	ld	s0,16(sp)
    80000dc0:	64a2                	ld	s1,8(sp)
    80000dc2:	6105                	addi	sp,sp,32
    80000dc4:	8082                	ret
    panic("acquire");
    80000dc6:	00007517          	auipc	a0,0x7
    80000dca:	2d250513          	addi	a0,a0,722 # 80008098 <digits+0x58>
    80000dce:	fffff097          	auipc	ra,0xfffff
    80000dd2:	772080e7          	jalr	1906(ra) # 80000540 <panic>

0000000080000dd6 <pop_off>:

void
pop_off(void)
{
    80000dd6:	1141                	addi	sp,sp,-16
    80000dd8:	e406                	sd	ra,8(sp)
    80000dda:	e022                	sd	s0,0(sp)
    80000ddc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dde:	00001097          	auipc	ra,0x1
    80000de2:	d88080e7          	jalr	-632(ra) # 80001b66 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000de6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dea:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dec:	e78d                	bnez	a5,80000e16 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dee:	5d3c                	lw	a5,120(a0)
    80000df0:	02f05b63          	blez	a5,80000e26 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000df4:	37fd                	addiw	a5,a5,-1
    80000df6:	0007871b          	sext.w	a4,a5
    80000dfa:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dfc:	eb09                	bnez	a4,80000e0e <pop_off+0x38>
    80000dfe:	5d7c                	lw	a5,124(a0)
    80000e00:	c799                	beqz	a5,80000e0e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e06:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e0a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e0e:	60a2                	ld	ra,8(sp)
    80000e10:	6402                	ld	s0,0(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret
    panic("pop_off - interruptible");
    80000e16:	00007517          	auipc	a0,0x7
    80000e1a:	28a50513          	addi	a0,a0,650 # 800080a0 <digits+0x60>
    80000e1e:	fffff097          	auipc	ra,0xfffff
    80000e22:	722080e7          	jalr	1826(ra) # 80000540 <panic>
    panic("pop_off");
    80000e26:	00007517          	auipc	a0,0x7
    80000e2a:	29250513          	addi	a0,a0,658 # 800080b8 <digits+0x78>
    80000e2e:	fffff097          	auipc	ra,0xfffff
    80000e32:	712080e7          	jalr	1810(ra) # 80000540 <panic>

0000000080000e36 <release>:
{
    80000e36:	1101                	addi	sp,sp,-32
    80000e38:	ec06                	sd	ra,24(sp)
    80000e3a:	e822                	sd	s0,16(sp)
    80000e3c:	e426                	sd	s1,8(sp)
    80000e3e:	1000                	addi	s0,sp,32
    80000e40:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e42:	00000097          	auipc	ra,0x0
    80000e46:	ec6080e7          	jalr	-314(ra) # 80000d08 <holding>
    80000e4a:	c115                	beqz	a0,80000e6e <release+0x38>
  lk->cpu = 0;
    80000e4c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e50:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e54:	0f50000f          	fence	iorw,ow
    80000e58:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e5c:	00000097          	auipc	ra,0x0
    80000e60:	f7a080e7          	jalr	-134(ra) # 80000dd6 <pop_off>
}
    80000e64:	60e2                	ld	ra,24(sp)
    80000e66:	6442                	ld	s0,16(sp)
    80000e68:	64a2                	ld	s1,8(sp)
    80000e6a:	6105                	addi	sp,sp,32
    80000e6c:	8082                	ret
    panic("release");
    80000e6e:	00007517          	auipc	a0,0x7
    80000e72:	25250513          	addi	a0,a0,594 # 800080c0 <digits+0x80>
    80000e76:	fffff097          	auipc	ra,0xfffff
    80000e7a:	6ca080e7          	jalr	1738(ra) # 80000540 <panic>

0000000080000e7e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e84:	ca19                	beqz	a2,80000e9a <memset+0x1c>
    80000e86:	87aa                	mv	a5,a0
    80000e88:	1602                	slli	a2,a2,0x20
    80000e8a:	9201                	srli	a2,a2,0x20
    80000e8c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e90:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fee79de3          	bne	a5,a4,80000e90 <memset+0x12>
  }
  return dst;
}
    80000e9a:	6422                	ld	s0,8(sp)
    80000e9c:	0141                	addi	sp,sp,16
    80000e9e:	8082                	ret

0000000080000ea0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ea0:	1141                	addi	sp,sp,-16
    80000ea2:	e422                	sd	s0,8(sp)
    80000ea4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ea6:	ca05                	beqz	a2,80000ed6 <memcmp+0x36>
    80000ea8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000eac:	1682                	slli	a3,a3,0x20
    80000eae:	9281                	srli	a3,a3,0x20
    80000eb0:	0685                	addi	a3,a3,1
    80000eb2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000eb4:	00054783          	lbu	a5,0(a0)
    80000eb8:	0005c703          	lbu	a4,0(a1)
    80000ebc:	00e79863          	bne	a5,a4,80000ecc <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ec0:	0505                	addi	a0,a0,1
    80000ec2:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ec4:	fed518e3          	bne	a0,a3,80000eb4 <memcmp+0x14>
  }

  return 0;
    80000ec8:	4501                	li	a0,0
    80000eca:	a019                	j	80000ed0 <memcmp+0x30>
      return *s1 - *s2;
    80000ecc:	40e7853b          	subw	a0,a5,a4
}
    80000ed0:	6422                	ld	s0,8(sp)
    80000ed2:	0141                	addi	sp,sp,16
    80000ed4:	8082                	ret
  return 0;
    80000ed6:	4501                	li	a0,0
    80000ed8:	bfe5                	j	80000ed0 <memcmp+0x30>

0000000080000eda <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000eda:	1141                	addi	sp,sp,-16
    80000edc:	e422                	sd	s0,8(sp)
    80000ede:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ee0:	c205                	beqz	a2,80000f00 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ee2:	02a5e263          	bltu	a1,a0,80000f06 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ee6:	1602                	slli	a2,a2,0x20
    80000ee8:	9201                	srli	a2,a2,0x20
    80000eea:	00c587b3          	add	a5,a1,a2
{
    80000eee:	872a                	mv	a4,a0
      *d++ = *s++;
    80000ef0:	0585                	addi	a1,a1,1
    80000ef2:	0705                	addi	a4,a4,1
    80000ef4:	fff5c683          	lbu	a3,-1(a1)
    80000ef8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000efc:	fef59ae3          	bne	a1,a5,80000ef0 <memmove+0x16>

  return dst;
}
    80000f00:	6422                	ld	s0,8(sp)
    80000f02:	0141                	addi	sp,sp,16
    80000f04:	8082                	ret
  if(s < d && s + n > d){
    80000f06:	02061693          	slli	a3,a2,0x20
    80000f0a:	9281                	srli	a3,a3,0x20
    80000f0c:	00d58733          	add	a4,a1,a3
    80000f10:	fce57be3          	bgeu	a0,a4,80000ee6 <memmove+0xc>
    d += n;
    80000f14:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f16:	fff6079b          	addiw	a5,a2,-1
    80000f1a:	1782                	slli	a5,a5,0x20
    80000f1c:	9381                	srli	a5,a5,0x20
    80000f1e:	fff7c793          	not	a5,a5
    80000f22:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f24:	177d                	addi	a4,a4,-1
    80000f26:	16fd                	addi	a3,a3,-1
    80000f28:	00074603          	lbu	a2,0(a4)
    80000f2c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f30:	fee79ae3          	bne	a5,a4,80000f24 <memmove+0x4a>
    80000f34:	b7f1                	j	80000f00 <memmove+0x26>

0000000080000f36 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f36:	1141                	addi	sp,sp,-16
    80000f38:	e406                	sd	ra,8(sp)
    80000f3a:	e022                	sd	s0,0(sp)
    80000f3c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	f9c080e7          	jalr	-100(ra) # 80000eda <memmove>
}
    80000f46:	60a2                	ld	ra,8(sp)
    80000f48:	6402                	ld	s0,0(sp)
    80000f4a:	0141                	addi	sp,sp,16
    80000f4c:	8082                	ret

0000000080000f4e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f4e:	1141                	addi	sp,sp,-16
    80000f50:	e422                	sd	s0,8(sp)
    80000f52:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f54:	ce11                	beqz	a2,80000f70 <strncmp+0x22>
    80000f56:	00054783          	lbu	a5,0(a0)
    80000f5a:	cf89                	beqz	a5,80000f74 <strncmp+0x26>
    80000f5c:	0005c703          	lbu	a4,0(a1)
    80000f60:	00f71a63          	bne	a4,a5,80000f74 <strncmp+0x26>
    n--, p++, q++;
    80000f64:	367d                	addiw	a2,a2,-1
    80000f66:	0505                	addi	a0,a0,1
    80000f68:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f6a:	f675                	bnez	a2,80000f56 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f6c:	4501                	li	a0,0
    80000f6e:	a809                	j	80000f80 <strncmp+0x32>
    80000f70:	4501                	li	a0,0
    80000f72:	a039                	j	80000f80 <strncmp+0x32>
  if(n == 0)
    80000f74:	ca09                	beqz	a2,80000f86 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f76:	00054503          	lbu	a0,0(a0)
    80000f7a:	0005c783          	lbu	a5,0(a1)
    80000f7e:	9d1d                	subw	a0,a0,a5
}
    80000f80:	6422                	ld	s0,8(sp)
    80000f82:	0141                	addi	sp,sp,16
    80000f84:	8082                	ret
    return 0;
    80000f86:	4501                	li	a0,0
    80000f88:	bfe5                	j	80000f80 <strncmp+0x32>

0000000080000f8a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f8a:	1141                	addi	sp,sp,-16
    80000f8c:	e422                	sd	s0,8(sp)
    80000f8e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f90:	872a                	mv	a4,a0
    80000f92:	8832                	mv	a6,a2
    80000f94:	367d                	addiw	a2,a2,-1
    80000f96:	01005963          	blez	a6,80000fa8 <strncpy+0x1e>
    80000f9a:	0705                	addi	a4,a4,1
    80000f9c:	0005c783          	lbu	a5,0(a1)
    80000fa0:	fef70fa3          	sb	a5,-1(a4)
    80000fa4:	0585                	addi	a1,a1,1
    80000fa6:	f7f5                	bnez	a5,80000f92 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fa8:	86ba                	mv	a3,a4
    80000faa:	00c05c63          	blez	a2,80000fc2 <strncpy+0x38>
    *s++ = 0;
    80000fae:	0685                	addi	a3,a3,1
    80000fb0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fb4:	40d707bb          	subw	a5,a4,a3
    80000fb8:	37fd                	addiw	a5,a5,-1
    80000fba:	010787bb          	addw	a5,a5,a6
    80000fbe:	fef048e3          	bgtz	a5,80000fae <strncpy+0x24>
  return os;
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fc8:	1141                	addi	sp,sp,-16
    80000fca:	e422                	sd	s0,8(sp)
    80000fcc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fce:	02c05363          	blez	a2,80000ff4 <safestrcpy+0x2c>
    80000fd2:	fff6069b          	addiw	a3,a2,-1
    80000fd6:	1682                	slli	a3,a3,0x20
    80000fd8:	9281                	srli	a3,a3,0x20
    80000fda:	96ae                	add	a3,a3,a1
    80000fdc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fde:	00d58963          	beq	a1,a3,80000ff0 <safestrcpy+0x28>
    80000fe2:	0585                	addi	a1,a1,1
    80000fe4:	0785                	addi	a5,a5,1
    80000fe6:	fff5c703          	lbu	a4,-1(a1)
    80000fea:	fee78fa3          	sb	a4,-1(a5)
    80000fee:	fb65                	bnez	a4,80000fde <safestrcpy+0x16>
    ;
  *s = 0;
    80000ff0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ff4:	6422                	ld	s0,8(sp)
    80000ff6:	0141                	addi	sp,sp,16
    80000ff8:	8082                	ret

0000000080000ffa <strlen>:

int
strlen(const char *s)
{
    80000ffa:	1141                	addi	sp,sp,-16
    80000ffc:	e422                	sd	s0,8(sp)
    80000ffe:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001000:	00054783          	lbu	a5,0(a0)
    80001004:	cf91                	beqz	a5,80001020 <strlen+0x26>
    80001006:	0505                	addi	a0,a0,1
    80001008:	87aa                	mv	a5,a0
    8000100a:	4685                	li	a3,1
    8000100c:	9e89                	subw	a3,a3,a0
    8000100e:	00f6853b          	addw	a0,a3,a5
    80001012:	0785                	addi	a5,a5,1
    80001014:	fff7c703          	lbu	a4,-1(a5)
    80001018:	fb7d                	bnez	a4,8000100e <strlen+0x14>
    ;
  return n;
}
    8000101a:	6422                	ld	s0,8(sp)
    8000101c:	0141                	addi	sp,sp,16
    8000101e:	8082                	ret
  for(n = 0; s[n]; n++)
    80001020:	4501                	li	a0,0
    80001022:	bfe5                	j	8000101a <strlen+0x20>

0000000080001024 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001024:	1141                	addi	sp,sp,-16
    80001026:	e406                	sd	ra,8(sp)
    80001028:	e022                	sd	s0,0(sp)
    8000102a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000102c:	00001097          	auipc	ra,0x1
    80001030:	b2a080e7          	jalr	-1238(ra) # 80001b56 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001034:	00008717          	auipc	a4,0x8
    80001038:	bc470713          	addi	a4,a4,-1084 # 80008bf8 <started>
  if(cpuid() == 0){
    8000103c:	c139                	beqz	a0,80001082 <main+0x5e>
    while(started == 0)
    8000103e:	431c                	lw	a5,0(a4)
    80001040:	2781                	sext.w	a5,a5
    80001042:	dff5                	beqz	a5,8000103e <main+0x1a>
      ;
    __sync_synchronize();
    80001044:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001048:	00001097          	auipc	ra,0x1
    8000104c:	b0e080e7          	jalr	-1266(ra) # 80001b56 <cpuid>
    80001050:	85aa                	mv	a1,a0
    80001052:	00007517          	auipc	a0,0x7
    80001056:	08e50513          	addi	a0,a0,142 # 800080e0 <digits+0xa0>
    8000105a:	fffff097          	auipc	ra,0xfffff
    8000105e:	530080e7          	jalr	1328(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80001062:	00000097          	auipc	ra,0x0
    80001066:	0d8080e7          	jalr	216(ra) # 8000113a <kvminithart>
    trapinithart();   // install kernel trap vector
    8000106a:	00002097          	auipc	ra,0x2
    8000106e:	9bc080e7          	jalr	-1604(ra) # 80002a26 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001072:	00005097          	auipc	ra,0x5
    80001076:	2fe080e7          	jalr	766(ra) # 80006370 <plicinithart>
  }

  // srand(time(NULL));
  scheduler();        
    8000107a:	00001097          	auipc	ra,0x1
    8000107e:	090080e7          	jalr	144(ra) # 8000210a <scheduler>
    consoleinit();
    80001082:	fffff097          	auipc	ra,0xfffff
    80001086:	3ce080e7          	jalr	974(ra) # 80000450 <consoleinit>
    printfinit();
    8000108a:	fffff097          	auipc	ra,0xfffff
    8000108e:	6e0080e7          	jalr	1760(ra) # 8000076a <printfinit>
    printf("\n");
    80001092:	00007517          	auipc	a0,0x7
    80001096:	05e50513          	addi	a0,a0,94 # 800080f0 <digits+0xb0>
    8000109a:	fffff097          	auipc	ra,0xfffff
    8000109e:	4f0080e7          	jalr	1264(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    800010a2:	00007517          	auipc	a0,0x7
    800010a6:	02650513          	addi	a0,a0,38 # 800080c8 <digits+0x88>
    800010aa:	fffff097          	auipc	ra,0xfffff
    800010ae:	4e0080e7          	jalr	1248(ra) # 8000058a <printf>
    printf("\n");
    800010b2:	00007517          	auipc	a0,0x7
    800010b6:	03e50513          	addi	a0,a0,62 # 800080f0 <digits+0xb0>
    800010ba:	fffff097          	auipc	ra,0xfffff
    800010be:	4d0080e7          	jalr	1232(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    800010c2:	00000097          	auipc	ra,0x0
    800010c6:	b56080e7          	jalr	-1194(ra) # 80000c18 <kinit>
    kvminit();       // create kernel page table
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	326080e7          	jalr	806(ra) # 800013f0 <kvminit>
    kvminithart();   // turn on paging
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	068080e7          	jalr	104(ra) # 8000113a <kvminithart>
    procinit();      // process table
    800010da:	00001097          	auipc	ra,0x1
    800010de:	9c8080e7          	jalr	-1592(ra) # 80001aa2 <procinit>
    trapinit();      // trap vectors
    800010e2:	00002097          	auipc	ra,0x2
    800010e6:	91c080e7          	jalr	-1764(ra) # 800029fe <trapinit>
    trapinithart();  // install kernel trap vector
    800010ea:	00002097          	auipc	ra,0x2
    800010ee:	93c080e7          	jalr	-1732(ra) # 80002a26 <trapinithart>
    plicinit();      // set up interrupt controller
    800010f2:	00005097          	auipc	ra,0x5
    800010f6:	268080e7          	jalr	616(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010fa:	00005097          	auipc	ra,0x5
    800010fe:	276080e7          	jalr	630(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80001102:	00002097          	auipc	ra,0x2
    80001106:	410080e7          	jalr	1040(ra) # 80003512 <binit>
    iinit();         // inode table
    8000110a:	00003097          	auipc	ra,0x3
    8000110e:	ab0080e7          	jalr	-1360(ra) # 80003bba <iinit>
    fileinit();      // file table
    80001112:	00004097          	auipc	ra,0x4
    80001116:	a56080e7          	jalr	-1450(ra) # 80004b68 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000111a:	00005097          	auipc	ra,0x5
    8000111e:	35e080e7          	jalr	862(ra) # 80006478 <virtio_disk_init>
    userinit();      // first user process
    80001122:	00001097          	auipc	ra,0x1
    80001126:	d64080e7          	jalr	-668(ra) # 80001e86 <userinit>
    __sync_synchronize();
    8000112a:	0ff0000f          	fence
    started = 1;
    8000112e:	4785                	li	a5,1
    80001130:	00008717          	auipc	a4,0x8
    80001134:	acf72423          	sw	a5,-1336(a4) # 80008bf8 <started>
    80001138:	b789                	j	8000107a <main+0x56>

000000008000113a <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    8000113a:	1141                	addi	sp,sp,-16
    8000113c:	e422                	sd	s0,8(sp)
    8000113e:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001140:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001144:	00008797          	auipc	a5,0x8
    80001148:	abc7b783          	ld	a5,-1348(a5) # 80008c00 <kernel_pagetable>
    8000114c:	83b1                	srli	a5,a5,0xc
    8000114e:	577d                	li	a4,-1
    80001150:	177e                	slli	a4,a4,0x3f
    80001152:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001154:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001158:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000115c:	6422                	ld	s0,8(sp)
    8000115e:	0141                	addi	sp,sp,16
    80001160:	8082                	ret

0000000080001162 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001162:	7139                	addi	sp,sp,-64
    80001164:	fc06                	sd	ra,56(sp)
    80001166:	f822                	sd	s0,48(sp)
    80001168:	f426                	sd	s1,40(sp)
    8000116a:	f04a                	sd	s2,32(sp)
    8000116c:	ec4e                	sd	s3,24(sp)
    8000116e:	e852                	sd	s4,16(sp)
    80001170:	e456                	sd	s5,8(sp)
    80001172:	e05a                	sd	s6,0(sp)
    80001174:	0080                	addi	s0,sp,64
    80001176:	84aa                	mv	s1,a0
    80001178:	89ae                	mv	s3,a1
    8000117a:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    8000117c:	57fd                	li	a5,-1
    8000117e:	83e9                	srli	a5,a5,0x1a
    80001180:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    80001182:	4b31                	li	s6,12
  if (va >= MAXVA)
    80001184:	04b7f263          	bgeu	a5,a1,800011c8 <walk+0x66>
    panic("walk");
    80001188:	00007517          	auipc	a0,0x7
    8000118c:	f7050513          	addi	a0,a0,-144 # 800080f8 <digits+0xb8>
    80001190:	fffff097          	auipc	ra,0xfffff
    80001194:	3b0080e7          	jalr	944(ra) # 80000540 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001198:	060a8663          	beqz	s5,80001204 <walk+0xa2>
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	ab8080e7          	jalr	-1352(ra) # 80000c54 <kalloc>
    800011a4:	84aa                	mv	s1,a0
    800011a6:	c529                	beqz	a0,800011f0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011a8:	6605                	lui	a2,0x1
    800011aa:	4581                	li	a1,0
    800011ac:	00000097          	auipc	ra,0x0
    800011b0:	cd2080e7          	jalr	-814(ra) # 80000e7e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011b4:	00c4d793          	srli	a5,s1,0xc
    800011b8:	07aa                	slli	a5,a5,0xa
    800011ba:	0017e793          	ori	a5,a5,1
    800011be:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    800011c2:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    800011c4:	036a0063          	beq	s4,s6,800011e4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011c8:	0149d933          	srl	s2,s3,s4
    800011cc:	1ff97913          	andi	s2,s2,511
    800011d0:	090e                	slli	s2,s2,0x3
    800011d2:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    800011d4:	00093483          	ld	s1,0(s2)
    800011d8:	0014f793          	andi	a5,s1,1
    800011dc:	dfd5                	beqz	a5,80001198 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011de:	80a9                	srli	s1,s1,0xa
    800011e0:	04b2                	slli	s1,s1,0xc
    800011e2:	b7c5                	j	800011c2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011e4:	00c9d513          	srli	a0,s3,0xc
    800011e8:	1ff57513          	andi	a0,a0,511
    800011ec:	050e                	slli	a0,a0,0x3
    800011ee:	9526                	add	a0,a0,s1
}
    800011f0:	70e2                	ld	ra,56(sp)
    800011f2:	7442                	ld	s0,48(sp)
    800011f4:	74a2                	ld	s1,40(sp)
    800011f6:	7902                	ld	s2,32(sp)
    800011f8:	69e2                	ld	s3,24(sp)
    800011fa:	6a42                	ld	s4,16(sp)
    800011fc:	6aa2                	ld	s5,8(sp)
    800011fe:	6b02                	ld	s6,0(sp)
    80001200:	6121                	addi	sp,sp,64
    80001202:	8082                	ret
        return 0;
    80001204:	4501                	li	a0,0
    80001206:	b7ed                	j	800011f0 <walk+0x8e>

0000000080001208 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    80001208:	57fd                	li	a5,-1
    8000120a:	83e9                	srli	a5,a5,0x1a
    8000120c:	00b7f463          	bgeu	a5,a1,80001214 <walkaddr+0xc>
    return 0;
    80001210:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001212:	8082                	ret
{
    80001214:	1141                	addi	sp,sp,-16
    80001216:	e406                	sd	ra,8(sp)
    80001218:	e022                	sd	s0,0(sp)
    8000121a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000121c:	4601                	li	a2,0
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f44080e7          	jalr	-188(ra) # 80001162 <walk>
  if (pte == 0)
    80001226:	c105                	beqz	a0,80001246 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    80001228:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    8000122a:	0117f693          	andi	a3,a5,17
    8000122e:	4745                	li	a4,17
    return 0;
    80001230:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001232:	00e68663          	beq	a3,a4,8000123e <walkaddr+0x36>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	addi	sp,sp,16
    8000123c:	8082                	ret
  pa = PTE2PA(*pte);
    8000123e:	83a9                	srli	a5,a5,0xa
    80001240:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001244:	bfcd                	j	80001236 <walkaddr+0x2e>
    return 0;
    80001246:	4501                	li	a0,0
    80001248:	b7fd                	j	80001236 <walkaddr+0x2e>

000000008000124a <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000124a:	715d                	addi	sp,sp,-80
    8000124c:	e486                	sd	ra,72(sp)
    8000124e:	e0a2                	sd	s0,64(sp)
    80001250:	fc26                	sd	s1,56(sp)
    80001252:	f84a                	sd	s2,48(sp)
    80001254:	f44e                	sd	s3,40(sp)
    80001256:	f052                	sd	s4,32(sp)
    80001258:	ec56                	sd	s5,24(sp)
    8000125a:	e85a                	sd	s6,16(sp)
    8000125c:	e45e                	sd	s7,8(sp)
    8000125e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    80001260:	c639                	beqz	a2,800012ae <mappages+0x64>
    80001262:	8aaa                	mv	s5,a0
    80001264:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001266:	777d                	lui	a4,0xfffff
    80001268:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000126c:	fff58993          	addi	s3,a1,-1
    80001270:	99b2                	add	s3,s3,a2
    80001272:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001276:	893e                	mv	s2,a5
    80001278:	40f68a33          	sub	s4,a3,a5
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    8000127c:	6b85                	lui	s7,0x1
    8000127e:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001282:	4605                	li	a2,1
    80001284:	85ca                	mv	a1,s2
    80001286:	8556                	mv	a0,s5
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	eda080e7          	jalr	-294(ra) # 80001162 <walk>
    80001290:	cd1d                	beqz	a0,800012ce <mappages+0x84>
    if (*pte & PTE_V)
    80001292:	611c                	ld	a5,0(a0)
    80001294:	8b85                	andi	a5,a5,1
    80001296:	e785                	bnez	a5,800012be <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001298:	80b1                	srli	s1,s1,0xc
    8000129a:	04aa                	slli	s1,s1,0xa
    8000129c:	0164e4b3          	or	s1,s1,s6
    800012a0:	0014e493          	ori	s1,s1,1
    800012a4:	e104                	sd	s1,0(a0)
    if (a == last)
    800012a6:	05390063          	beq	s2,s3,800012e6 <mappages+0x9c>
    a += PGSIZE;
    800012aa:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    800012ac:	bfc9                	j	8000127e <mappages+0x34>
    panic("mappages: size");
    800012ae:	00007517          	auipc	a0,0x7
    800012b2:	e5250513          	addi	a0,a0,-430 # 80008100 <digits+0xc0>
    800012b6:	fffff097          	auipc	ra,0xfffff
    800012ba:	28a080e7          	jalr	650(ra) # 80000540 <panic>
      panic("mappages: remap");
    800012be:	00007517          	auipc	a0,0x7
    800012c2:	e5250513          	addi	a0,a0,-430 # 80008110 <digits+0xd0>
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	27a080e7          	jalr	634(ra) # 80000540 <panic>
      return -1;
    800012ce:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012d0:	60a6                	ld	ra,72(sp)
    800012d2:	6406                	ld	s0,64(sp)
    800012d4:	74e2                	ld	s1,56(sp)
    800012d6:	7942                	ld	s2,48(sp)
    800012d8:	79a2                	ld	s3,40(sp)
    800012da:	7a02                	ld	s4,32(sp)
    800012dc:	6ae2                	ld	s5,24(sp)
    800012de:	6b42                	ld	s6,16(sp)
    800012e0:	6ba2                	ld	s7,8(sp)
    800012e2:	6161                	addi	sp,sp,80
    800012e4:	8082                	ret
  return 0;
    800012e6:	4501                	li	a0,0
    800012e8:	b7e5                	j	800012d0 <mappages+0x86>

00000000800012ea <kvmmap>:
{
    800012ea:	1141                	addi	sp,sp,-16
    800012ec:	e406                	sd	ra,8(sp)
    800012ee:	e022                	sd	s0,0(sp)
    800012f0:	0800                	addi	s0,sp,16
    800012f2:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012f4:	86b2                	mv	a3,a2
    800012f6:	863e                	mv	a2,a5
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	f52080e7          	jalr	-174(ra) # 8000124a <mappages>
    80001300:	e509                	bnez	a0,8000130a <kvmmap+0x20>
}
    80001302:	60a2                	ld	ra,8(sp)
    80001304:	6402                	ld	s0,0(sp)
    80001306:	0141                	addi	sp,sp,16
    80001308:	8082                	ret
    panic("kvmmap");
    8000130a:	00007517          	auipc	a0,0x7
    8000130e:	e1650513          	addi	a0,a0,-490 # 80008120 <digits+0xe0>
    80001312:	fffff097          	auipc	ra,0xfffff
    80001316:	22e080e7          	jalr	558(ra) # 80000540 <panic>

000000008000131a <kvmmake>:
{
    8000131a:	1101                	addi	sp,sp,-32
    8000131c:	ec06                	sd	ra,24(sp)
    8000131e:	e822                	sd	s0,16(sp)
    80001320:	e426                	sd	s1,8(sp)
    80001322:	e04a                	sd	s2,0(sp)
    80001324:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	92e080e7          	jalr	-1746(ra) # 80000c54 <kalloc>
    8000132e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001330:	6605                	lui	a2,0x1
    80001332:	4581                	li	a1,0
    80001334:	00000097          	auipc	ra,0x0
    80001338:	b4a080e7          	jalr	-1206(ra) # 80000e7e <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000133c:	4719                	li	a4,6
    8000133e:	6685                	lui	a3,0x1
    80001340:	10000637          	lui	a2,0x10000
    80001344:	100005b7          	lui	a1,0x10000
    80001348:	8526                	mv	a0,s1
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	fa0080e7          	jalr	-96(ra) # 800012ea <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001352:	4719                	li	a4,6
    80001354:	6685                	lui	a3,0x1
    80001356:	10001637          	lui	a2,0x10001
    8000135a:	100015b7          	lui	a1,0x10001
    8000135e:	8526                	mv	a0,s1
    80001360:	00000097          	auipc	ra,0x0
    80001364:	f8a080e7          	jalr	-118(ra) # 800012ea <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001368:	4719                	li	a4,6
    8000136a:	004006b7          	lui	a3,0x400
    8000136e:	0c000637          	lui	a2,0xc000
    80001372:	0c0005b7          	lui	a1,0xc000
    80001376:	8526                	mv	a0,s1
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	f72080e7          	jalr	-142(ra) # 800012ea <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80001380:	00007917          	auipc	s2,0x7
    80001384:	c8090913          	addi	s2,s2,-896 # 80008000 <etext>
    80001388:	4729                	li	a4,10
    8000138a:	80007697          	auipc	a3,0x80007
    8000138e:	c7668693          	addi	a3,a3,-906 # 8000 <_entry-0x7fff8000>
    80001392:	4605                	li	a2,1
    80001394:	067e                	slli	a2,a2,0x1f
    80001396:	85b2                	mv	a1,a2
    80001398:	8526                	mv	a0,s1
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	f50080e7          	jalr	-176(ra) # 800012ea <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800013a2:	4719                	li	a4,6
    800013a4:	46c5                	li	a3,17
    800013a6:	06ee                	slli	a3,a3,0x1b
    800013a8:	412686b3          	sub	a3,a3,s2
    800013ac:	864a                	mv	a2,s2
    800013ae:	85ca                	mv	a1,s2
    800013b0:	8526                	mv	a0,s1
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	f38080e7          	jalr	-200(ra) # 800012ea <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013ba:	4729                	li	a4,10
    800013bc:	6685                	lui	a3,0x1
    800013be:	00006617          	auipc	a2,0x6
    800013c2:	c4260613          	addi	a2,a2,-958 # 80007000 <_trampoline>
    800013c6:	040005b7          	lui	a1,0x4000
    800013ca:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013cc:	05b2                	slli	a1,a1,0xc
    800013ce:	8526                	mv	a0,s1
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	f1a080e7          	jalr	-230(ra) # 800012ea <kvmmap>
  proc_mapstacks(kpgtbl);
    800013d8:	8526                	mv	a0,s1
    800013da:	00000097          	auipc	ra,0x0
    800013de:	632080e7          	jalr	1586(ra) # 80001a0c <proc_mapstacks>
}
    800013e2:	8526                	mv	a0,s1
    800013e4:	60e2                	ld	ra,24(sp)
    800013e6:	6442                	ld	s0,16(sp)
    800013e8:	64a2                	ld	s1,8(sp)
    800013ea:	6902                	ld	s2,0(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret

00000000800013f0 <kvminit>:
{
    800013f0:	1141                	addi	sp,sp,-16
    800013f2:	e406                	sd	ra,8(sp)
    800013f4:	e022                	sd	s0,0(sp)
    800013f6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	f22080e7          	jalr	-222(ra) # 8000131a <kvmmake>
    80001400:	00008797          	auipc	a5,0x8
    80001404:	80a7b023          	sd	a0,-2048(a5) # 80008c00 <kernel_pagetable>
}
    80001408:	60a2                	ld	ra,8(sp)
    8000140a:	6402                	ld	s0,0(sp)
    8000140c:	0141                	addi	sp,sp,16
    8000140e:	8082                	ret

0000000080001410 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001410:	715d                	addi	sp,sp,-80
    80001412:	e486                	sd	ra,72(sp)
    80001414:	e0a2                	sd	s0,64(sp)
    80001416:	fc26                	sd	s1,56(sp)
    80001418:	f84a                	sd	s2,48(sp)
    8000141a:	f44e                	sd	s3,40(sp)
    8000141c:	f052                	sd	s4,32(sp)
    8000141e:	ec56                	sd	s5,24(sp)
    80001420:	e85a                	sd	s6,16(sp)
    80001422:	e45e                	sd	s7,8(sp)
    80001424:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    80001426:	03459793          	slli	a5,a1,0x34
    8000142a:	e795                	bnez	a5,80001456 <uvmunmap+0x46>
    8000142c:	8a2a                	mv	s4,a0
    8000142e:	892e                	mv	s2,a1
    80001430:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001432:	0632                	slli	a2,a2,0xc
    80001434:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    80001438:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000143a:	6b05                	lui	s6,0x1
    8000143c:	0735e263          	bltu	a1,s3,800014a0 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    80001440:	60a6                	ld	ra,72(sp)
    80001442:	6406                	ld	s0,64(sp)
    80001444:	74e2                	ld	s1,56(sp)
    80001446:	7942                	ld	s2,48(sp)
    80001448:	79a2                	ld	s3,40(sp)
    8000144a:	7a02                	ld	s4,32(sp)
    8000144c:	6ae2                	ld	s5,24(sp)
    8000144e:	6b42                	ld	s6,16(sp)
    80001450:	6ba2                	ld	s7,8(sp)
    80001452:	6161                	addi	sp,sp,80
    80001454:	8082                	ret
    panic("uvmunmap: not aligned");
    80001456:	00007517          	auipc	a0,0x7
    8000145a:	cd250513          	addi	a0,a0,-814 # 80008128 <digits+0xe8>
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	0e2080e7          	jalr	226(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001466:	00007517          	auipc	a0,0x7
    8000146a:	cda50513          	addi	a0,a0,-806 # 80008140 <digits+0x100>
    8000146e:	fffff097          	auipc	ra,0xfffff
    80001472:	0d2080e7          	jalr	210(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001476:	00007517          	auipc	a0,0x7
    8000147a:	cda50513          	addi	a0,a0,-806 # 80008150 <digits+0x110>
    8000147e:	fffff097          	auipc	ra,0xfffff
    80001482:	0c2080e7          	jalr	194(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001486:	00007517          	auipc	a0,0x7
    8000148a:	ce250513          	addi	a0,a0,-798 # 80008168 <digits+0x128>
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	0b2080e7          	jalr	178(ra) # 80000540 <panic>
    *pte = 0;
    80001496:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000149a:	995a                	add	s2,s2,s6
    8000149c:	fb3972e3          	bgeu	s2,s3,80001440 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    800014a0:	4601                	li	a2,0
    800014a2:	85ca                	mv	a1,s2
    800014a4:	8552                	mv	a0,s4
    800014a6:	00000097          	auipc	ra,0x0
    800014aa:	cbc080e7          	jalr	-836(ra) # 80001162 <walk>
    800014ae:	84aa                	mv	s1,a0
    800014b0:	d95d                	beqz	a0,80001466 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    800014b2:	6108                	ld	a0,0(a0)
    800014b4:	00157793          	andi	a5,a0,1
    800014b8:	dfdd                	beqz	a5,80001476 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    800014ba:	3ff57793          	andi	a5,a0,1023
    800014be:	fd7784e3          	beq	a5,s7,80001486 <uvmunmap+0x76>
    if (do_free)
    800014c2:	fc0a8ae3          	beqz	s5,80001496 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014c6:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    800014c8:	0532                	slli	a0,a0,0xc
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	5ea080e7          	jalr	1514(ra) # 80000ab4 <kfree>
    800014d2:	b7d1                	j	80001496 <uvmunmap+0x86>

00000000800014d4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014d4:	1101                	addi	sp,sp,-32
    800014d6:	ec06                	sd	ra,24(sp)
    800014d8:	e822                	sd	s0,16(sp)
    800014da:	e426                	sd	s1,8(sp)
    800014dc:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    800014de:	fffff097          	auipc	ra,0xfffff
    800014e2:	776080e7          	jalr	1910(ra) # 80000c54 <kalloc>
    800014e6:	84aa                	mv	s1,a0
  if (pagetable == 0)
    800014e8:	c519                	beqz	a0,800014f6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014ea:	6605                	lui	a2,0x1
    800014ec:	4581                	li	a1,0
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	990080e7          	jalr	-1648(ra) # 80000e7e <memset>
  return pagetable;
}
    800014f6:	8526                	mv	a0,s1
    800014f8:	60e2                	ld	ra,24(sp)
    800014fa:	6442                	ld	s0,16(sp)
    800014fc:	64a2                	ld	s1,8(sp)
    800014fe:	6105                	addi	sp,sp,32
    80001500:	8082                	ret

0000000080001502 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001502:	7179                	addi	sp,sp,-48
    80001504:	f406                	sd	ra,40(sp)
    80001506:	f022                	sd	s0,32(sp)
    80001508:	ec26                	sd	s1,24(sp)
    8000150a:	e84a                	sd	s2,16(sp)
    8000150c:	e44e                	sd	s3,8(sp)
    8000150e:	e052                	sd	s4,0(sp)
    80001510:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001512:	6785                	lui	a5,0x1
    80001514:	04f67863          	bgeu	a2,a5,80001564 <uvmfirst+0x62>
    80001518:	8a2a                	mv	s4,a0
    8000151a:	89ae                	mv	s3,a1
    8000151c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	736080e7          	jalr	1846(ra) # 80000c54 <kalloc>
    80001526:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001528:	6605                	lui	a2,0x1
    8000152a:	4581                	li	a1,0
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	952080e7          	jalr	-1710(ra) # 80000e7e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001534:	4779                	li	a4,30
    80001536:	86ca                	mv	a3,s2
    80001538:	6605                	lui	a2,0x1
    8000153a:	4581                	li	a1,0
    8000153c:	8552                	mv	a0,s4
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	d0c080e7          	jalr	-756(ra) # 8000124a <mappages>
  memmove(mem, src, sz);
    80001546:	8626                	mv	a2,s1
    80001548:	85ce                	mv	a1,s3
    8000154a:	854a                	mv	a0,s2
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	98e080e7          	jalr	-1650(ra) # 80000eda <memmove>
}
    80001554:	70a2                	ld	ra,40(sp)
    80001556:	7402                	ld	s0,32(sp)
    80001558:	64e2                	ld	s1,24(sp)
    8000155a:	6942                	ld	s2,16(sp)
    8000155c:	69a2                	ld	s3,8(sp)
    8000155e:	6a02                	ld	s4,0(sp)
    80001560:	6145                	addi	sp,sp,48
    80001562:	8082                	ret
    panic("uvmfirst: more than a page");
    80001564:	00007517          	auipc	a0,0x7
    80001568:	c1c50513          	addi	a0,a0,-996 # 80008180 <digits+0x140>
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	fd4080e7          	jalr	-44(ra) # 80000540 <panic>

0000000080001574 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001574:	1101                	addi	sp,sp,-32
    80001576:	ec06                	sd	ra,24(sp)
    80001578:	e822                	sd	s0,16(sp)
    8000157a:	e426                	sd	s1,8(sp)
    8000157c:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    8000157e:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    80001580:	00b67d63          	bgeu	a2,a1,8000159a <uvmdealloc+0x26>
    80001584:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001586:	6785                	lui	a5,0x1
    80001588:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000158a:	00f60733          	add	a4,a2,a5
    8000158e:	76fd                	lui	a3,0xfffff
    80001590:	8f75                	and	a4,a4,a3
    80001592:	97ae                	add	a5,a5,a1
    80001594:	8ff5                	and	a5,a5,a3
    80001596:	00f76863          	bltu	a4,a5,800015a6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000159a:	8526                	mv	a0,s1
    8000159c:	60e2                	ld	ra,24(sp)
    8000159e:	6442                	ld	s0,16(sp)
    800015a0:	64a2                	ld	s1,8(sp)
    800015a2:	6105                	addi	sp,sp,32
    800015a4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015a6:	8f99                	sub	a5,a5,a4
    800015a8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015aa:	4685                	li	a3,1
    800015ac:	0007861b          	sext.w	a2,a5
    800015b0:	85ba                	mv	a1,a4
    800015b2:	00000097          	auipc	ra,0x0
    800015b6:	e5e080e7          	jalr	-418(ra) # 80001410 <uvmunmap>
    800015ba:	b7c5                	j	8000159a <uvmdealloc+0x26>

00000000800015bc <uvmalloc>:
  if (newsz < oldsz)
    800015bc:	0ab66563          	bltu	a2,a1,80001666 <uvmalloc+0xaa>
{
    800015c0:	7139                	addi	sp,sp,-64
    800015c2:	fc06                	sd	ra,56(sp)
    800015c4:	f822                	sd	s0,48(sp)
    800015c6:	f426                	sd	s1,40(sp)
    800015c8:	f04a                	sd	s2,32(sp)
    800015ca:	ec4e                	sd	s3,24(sp)
    800015cc:	e852                	sd	s4,16(sp)
    800015ce:	e456                	sd	s5,8(sp)
    800015d0:	e05a                	sd	s6,0(sp)
    800015d2:	0080                	addi	s0,sp,64
    800015d4:	8aaa                	mv	s5,a0
    800015d6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d8:	6785                	lui	a5,0x1
    800015da:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015dc:	95be                	add	a1,a1,a5
    800015de:	77fd                	lui	a5,0xfffff
    800015e0:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    800015e4:	08c9f363          	bgeu	s3,a2,8000166a <uvmalloc+0xae>
    800015e8:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015ea:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	666080e7          	jalr	1638(ra) # 80000c54 <kalloc>
    800015f6:	84aa                	mv	s1,a0
    if (mem == 0)
    800015f8:	c51d                	beqz	a0,80001626 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015fa:	6605                	lui	a2,0x1
    800015fc:	4581                	li	a1,0
    800015fe:	00000097          	auipc	ra,0x0
    80001602:	880080e7          	jalr	-1920(ra) # 80000e7e <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001606:	875a                	mv	a4,s6
    80001608:	86a6                	mv	a3,s1
    8000160a:	6605                	lui	a2,0x1
    8000160c:	85ca                	mv	a1,s2
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c3a080e7          	jalr	-966(ra) # 8000124a <mappages>
    80001618:	e90d                	bnez	a0,8000164a <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000161a:	6785                	lui	a5,0x1
    8000161c:	993e                	add	s2,s2,a5
    8000161e:	fd4968e3          	bltu	s2,s4,800015ee <uvmalloc+0x32>
  return newsz;
    80001622:	8552                	mv	a0,s4
    80001624:	a809                	j	80001636 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001626:	864e                	mv	a2,s3
    80001628:	85ca                	mv	a1,s2
    8000162a:	8556                	mv	a0,s5
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	f48080e7          	jalr	-184(ra) # 80001574 <uvmdealloc>
      return 0;
    80001634:	4501                	li	a0,0
}
    80001636:	70e2                	ld	ra,56(sp)
    80001638:	7442                	ld	s0,48(sp)
    8000163a:	74a2                	ld	s1,40(sp)
    8000163c:	7902                	ld	s2,32(sp)
    8000163e:	69e2                	ld	s3,24(sp)
    80001640:	6a42                	ld	s4,16(sp)
    80001642:	6aa2                	ld	s5,8(sp)
    80001644:	6b02                	ld	s6,0(sp)
    80001646:	6121                	addi	sp,sp,64
    80001648:	8082                	ret
      kfree(mem);
    8000164a:	8526                	mv	a0,s1
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	468080e7          	jalr	1128(ra) # 80000ab4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001654:	864e                	mv	a2,s3
    80001656:	85ca                	mv	a1,s2
    80001658:	8556                	mv	a0,s5
    8000165a:	00000097          	auipc	ra,0x0
    8000165e:	f1a080e7          	jalr	-230(ra) # 80001574 <uvmdealloc>
      return 0;
    80001662:	4501                	li	a0,0
    80001664:	bfc9                	j	80001636 <uvmalloc+0x7a>
    return oldsz;
    80001666:	852e                	mv	a0,a1
}
    80001668:	8082                	ret
  return newsz;
    8000166a:	8532                	mv	a0,a2
    8000166c:	b7e9                	j	80001636 <uvmalloc+0x7a>

000000008000166e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    8000166e:	7179                	addi	sp,sp,-48
    80001670:	f406                	sd	ra,40(sp)
    80001672:	f022                	sd	s0,32(sp)
    80001674:	ec26                	sd	s1,24(sp)
    80001676:	e84a                	sd	s2,16(sp)
    80001678:	e44e                	sd	s3,8(sp)
    8000167a:	e052                	sd	s4,0(sp)
    8000167c:	1800                	addi	s0,sp,48
    8000167e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    80001680:	84aa                	mv	s1,a0
    80001682:	6905                	lui	s2,0x1
    80001684:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001686:	4985                	li	s3,1
    80001688:	a829                	j	800016a2 <freewalk+0x34>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000168a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000168c:	00c79513          	slli	a0,a5,0xc
    80001690:	00000097          	auipc	ra,0x0
    80001694:	fde080e7          	jalr	-34(ra) # 8000166e <freewalk>
      pagetable[i] = 0;
    80001698:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    8000169c:	04a1                	addi	s1,s1,8
    8000169e:	03248163          	beq	s1,s2,800016c0 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800016a2:	609c                	ld	a5,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800016a4:	00f7f713          	andi	a4,a5,15
    800016a8:	ff3701e3          	beq	a4,s3,8000168a <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    800016ac:	8b85                	andi	a5,a5,1
    800016ae:	d7fd                	beqz	a5,8000169c <freewalk+0x2e>
    {
      panic("freewalk: leaf");
    800016b0:	00007517          	auipc	a0,0x7
    800016b4:	af050513          	addi	a0,a0,-1296 # 800081a0 <digits+0x160>
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	e88080e7          	jalr	-376(ra) # 80000540 <panic>
    }
  }
  kfree((void *)pagetable);
    800016c0:	8552                	mv	a0,s4
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	3f2080e7          	jalr	1010(ra) # 80000ab4 <kfree>
}
    800016ca:	70a2                	ld	ra,40(sp)
    800016cc:	7402                	ld	s0,32(sp)
    800016ce:	64e2                	ld	s1,24(sp)
    800016d0:	6942                	ld	s2,16(sp)
    800016d2:	69a2                	ld	s3,8(sp)
    800016d4:	6a02                	ld	s4,0(sp)
    800016d6:	6145                	addi	sp,sp,48
    800016d8:	8082                	ret

00000000800016da <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016da:	1101                	addi	sp,sp,-32
    800016dc:	ec06                	sd	ra,24(sp)
    800016de:	e822                	sd	s0,16(sp)
    800016e0:	e426                	sd	s1,8(sp)
    800016e2:	1000                	addi	s0,sp,32
    800016e4:	84aa                	mv	s1,a0
  if (sz > 0)
    800016e6:	e999                	bnez	a1,800016fc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    800016e8:	8526                	mv	a0,s1
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	f84080e7          	jalr	-124(ra) # 8000166e <freewalk>
}
    800016f2:	60e2                	ld	ra,24(sp)
    800016f4:	6442                	ld	s0,16(sp)
    800016f6:	64a2                	ld	s1,8(sp)
    800016f8:	6105                	addi	sp,sp,32
    800016fa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800016fc:	6785                	lui	a5,0x1
    800016fe:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001700:	95be                	add	a1,a1,a5
    80001702:	4685                	li	a3,1
    80001704:	00c5d613          	srli	a2,a1,0xc
    80001708:	4581                	li	a1,0
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	d06080e7          	jalr	-762(ra) # 80001410 <uvmunmap>
    80001712:	bfd9                	j	800016e8 <uvmfree+0xe>

0000000080001714 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    80001714:	c271                	beqz	a2,800017d8 <uvmcopy+0xc4>
{
    80001716:	7139                	addi	sp,sp,-64
    80001718:	fc06                	sd	ra,56(sp)
    8000171a:	f822                	sd	s0,48(sp)
    8000171c:	f426                	sd	s1,40(sp)
    8000171e:	f04a                	sd	s2,32(sp)
    80001720:	ec4e                	sd	s3,24(sp)
    80001722:	e852                	sd	s4,16(sp)
    80001724:	e456                	sd	s5,8(sp)
    80001726:	e05a                	sd	s6,0(sp)
    80001728:	0080                	addi	s0,sp,64
    8000172a:	8aaa                	mv	s5,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	89b2                	mv	s3,a2
  for (i = 0; i < sz; i += PGSIZE)
    80001730:	4481                	li	s1,0
    80001732:	a0b9                	j	80001780 <uvmcopy+0x6c>
  {
    if ((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001734:	00007517          	auipc	a0,0x7
    80001738:	a7c50513          	addi	a0,a0,-1412 # 800081b0 <digits+0x170>
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	e04080e7          	jalr	-508(ra) # 80000540 <panic>
    if ((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    80001744:	00007517          	auipc	a0,0x7
    80001748:	a8c50513          	addi	a0,a0,-1396 # 800081d0 <digits+0x190>
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	df4080e7          	jalr	-524(ra) # 80000540 <panic>
    // flags = PTE_FLAGS(*pte);
    // if((mem = kalloc()) == 0)          //COW
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);

    increase_paref(pa);
    80001754:	854a                	mv	a0,s2
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	292080e7          	jalr	658(ra) # 800009e8 <increase_paref>
    8000175e:	12000073          	sfence.vma
    // flush tlb
    sfence_vma();

    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80001762:	100b6713          	ori	a4,s6,256
    80001766:	86ca                	mv	a3,s2
    80001768:	6605                	lui	a2,0x1
    8000176a:	85a6                	mv	a1,s1
    8000176c:	8552                	mv	a0,s4
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	adc080e7          	jalr	-1316(ra) # 8000124a <mappages>
    80001776:	ed0d                	bnez	a0,800017b0 <uvmcopy+0x9c>
  for (i = 0; i < sz; i += PGSIZE)
    80001778:	6785                	lui	a5,0x1
    8000177a:	94be                	add	s1,s1,a5
    8000177c:	0534f463          	bgeu	s1,s3,800017c4 <uvmcopy+0xb0>
    if ((pte = walk(old, i, 0)) == 0)
    80001780:	4601                	li	a2,0
    80001782:	85a6                	mv	a1,s1
    80001784:	8556                	mv	a0,s5
    80001786:	00000097          	auipc	ra,0x0
    8000178a:	9dc080e7          	jalr	-1572(ra) # 80001162 <walk>
    8000178e:	d15d                	beqz	a0,80001734 <uvmcopy+0x20>
    if ((*pte & PTE_V) == 0)
    80001790:	611c                	ld	a5,0(a0)
    80001792:	0017f713          	andi	a4,a5,1
    80001796:	d75d                	beqz	a4,80001744 <uvmcopy+0x30>
    pa = PTE2PA(*pte);
    80001798:	00a7d913          	srli	s2,a5,0xa
    8000179c:	0932                	slli	s2,s2,0xc
    flags = PTE_FLAGS(*pte);
    8000179e:	0007871b          	sext.w	a4,a5
    if (flags & PTE_W)
    800017a2:	8b91                	andi	a5,a5,4
      flags &= (~PTE_W);
    800017a4:	3fb77b13          	andi	s6,a4,1019
    if (flags & PTE_W)
    800017a8:	f7d5                	bnez	a5,80001754 <uvmcopy+0x40>
    flags = PTE_FLAGS(*pte);
    800017aa:	3ff77b13          	andi	s6,a4,1023
    800017ae:	b75d                	j	80001754 <uvmcopy+0x40>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017b0:	4685                	li	a3,1
    800017b2:	00c4d613          	srli	a2,s1,0xc
    800017b6:	4581                	li	a1,0
    800017b8:	8552                	mv	a0,s4
    800017ba:	00000097          	auipc	ra,0x0
    800017be:	c56080e7          	jalr	-938(ra) # 80001410 <uvmunmap>
  return -1;
    800017c2:	557d                	li	a0,-1
}
    800017c4:	70e2                	ld	ra,56(sp)
    800017c6:	7442                	ld	s0,48(sp)
    800017c8:	74a2                	ld	s1,40(sp)
    800017ca:	7902                	ld	s2,32(sp)
    800017cc:	69e2                	ld	s3,24(sp)
    800017ce:	6a42                	ld	s4,16(sp)
    800017d0:	6aa2                	ld	s5,8(sp)
    800017d2:	6b02                	ld	s6,0(sp)
    800017d4:	6121                	addi	sp,sp,64
    800017d6:	8082                	ret
  return 0;
    800017d8:	4501                	li	a0,0
}
    800017da:	8082                	ret

00000000800017dc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    800017dc:	1141                	addi	sp,sp,-16
    800017de:	e406                	sd	ra,8(sp)
    800017e0:	e022                	sd	s0,0(sp)
    800017e2:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    800017e4:	4601                	li	a2,0
    800017e6:	00000097          	auipc	ra,0x0
    800017ea:	97c080e7          	jalr	-1668(ra) # 80001162 <walk>
  if (pte == 0)
    800017ee:	c901                	beqz	a0,800017fe <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017f0:	611c                	ld	a5,0(a0)
    800017f2:	9bbd                	andi	a5,a5,-17
    800017f4:	e11c                	sd	a5,0(a0)
}
    800017f6:	60a2                	ld	ra,8(sp)
    800017f8:	6402                	ld	s0,0(sp)
    800017fa:	0141                	addi	sp,sp,16
    800017fc:	8082                	ret
    panic("uvmclear");
    800017fe:	00007517          	auipc	a0,0x7
    80001802:	9f250513          	addi	a0,a0,-1550 # 800081f0 <digits+0x1b0>
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	d3a080e7          	jalr	-710(ra) # 80000540 <panic>

000000008000180e <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    8000180e:	cad1                	beqz	a3,800018a2 <copyout+0x94>
{
    80001810:	711d                	addi	sp,sp,-96
    80001812:	ec86                	sd	ra,88(sp)
    80001814:	e8a2                	sd	s0,80(sp)
    80001816:	e4a6                	sd	s1,72(sp)
    80001818:	e0ca                	sd	s2,64(sp)
    8000181a:	fc4e                	sd	s3,56(sp)
    8000181c:	f852                	sd	s4,48(sp)
    8000181e:	f456                	sd	s5,40(sp)
    80001820:	f05a                	sd	s6,32(sp)
    80001822:	ec5e                	sd	s7,24(sp)
    80001824:	e862                	sd	s8,16(sp)
    80001826:	e466                	sd	s9,8(sp)
    80001828:	1080                	addi	s0,sp,96
    8000182a:	8baa                	mv	s7,a0
    8000182c:	8aae                	mv	s5,a1
    8000182e:	8b32                	mv	s6,a2
    80001830:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(dstva);
    80001832:	74fd                	lui	s1,0xfffff
    80001834:	8ced                	and	s1,s1,a1
    if (va0 > MAXVA)
    80001836:	4785                	li	a5,1
    80001838:	179a                	slli	a5,a5,0x26
    8000183a:	0697e663          	bltu	a5,s1,800018a6 <copyout+0x98>
    8000183e:	6c85                	lui	s9,0x1
    80001840:	04000c37          	lui	s8,0x4000
    80001844:	0c05                	addi	s8,s8,1 # 4000001 <_entry-0x7bffffff>
    80001846:	0c32                	slli	s8,s8,0xc
    80001848:	a025                	j	80001870 <copyout+0x62>
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000184a:	409a84b3          	sub	s1,s5,s1
    8000184e:	0009061b          	sext.w	a2,s2
    80001852:	85da                	mv	a1,s6
    80001854:	9526                	add	a0,a0,s1
    80001856:	fffff097          	auipc	ra,0xfffff
    8000185a:	684080e7          	jalr	1668(ra) # 80000eda <memmove>

    len -= n;
    8000185e:	412989b3          	sub	s3,s3,s2
    src += n;
    80001862:	9b4a                	add	s6,s6,s2
  while (len > 0)
    80001864:	02098d63          	beqz	s3,8000189e <copyout+0x90>
    if (va0 > MAXVA)
    80001868:	058a0163          	beq	s4,s8,800018aa <copyout+0x9c>
    va0 = PGROUNDDOWN(dstva);
    8000186c:	84d2                	mv	s1,s4
    dstva = va0 + PGSIZE;
    8000186e:	8ad2                	mv	s5,s4
    if (cow_fault(pagetable, va0) < 0)
    80001870:	85a6                	mv	a1,s1
    80001872:	855e                	mv	a0,s7
    80001874:	00001097          	auipc	ra,0x1
    80001878:	422080e7          	jalr	1058(ra) # 80002c96 <cow_fault>
    8000187c:	02054963          	bltz	a0,800018ae <copyout+0xa0>
    pa0 = walkaddr(pagetable, va0);
    80001880:	85a6                	mv	a1,s1
    80001882:	855e                	mv	a0,s7
    80001884:	00000097          	auipc	ra,0x0
    80001888:	984080e7          	jalr	-1660(ra) # 80001208 <walkaddr>
    if (pa0 == 0)
    8000188c:	cd1d                	beqz	a0,800018ca <copyout+0xbc>
    n = PGSIZE - (dstva - va0);
    8000188e:	01948a33          	add	s4,s1,s9
    80001892:	415a0933          	sub	s2,s4,s5
    80001896:	fb29fae3          	bgeu	s3,s2,8000184a <copyout+0x3c>
    8000189a:	894e                	mv	s2,s3
    8000189c:	b77d                	j	8000184a <copyout+0x3c>
  }
  return 0;
    8000189e:	4501                	li	a0,0
    800018a0:	a801                	j	800018b0 <copyout+0xa2>
    800018a2:	4501                	li	a0,0
}
    800018a4:	8082                	ret
      return -1;
    800018a6:	557d                	li	a0,-1
    800018a8:	a021                	j	800018b0 <copyout+0xa2>
    800018aa:	557d                	li	a0,-1
    800018ac:	a011                	j	800018b0 <copyout+0xa2>
      return -1;
    800018ae:	557d                	li	a0,-1
}
    800018b0:	60e6                	ld	ra,88(sp)
    800018b2:	6446                	ld	s0,80(sp)
    800018b4:	64a6                	ld	s1,72(sp)
    800018b6:	6906                	ld	s2,64(sp)
    800018b8:	79e2                	ld	s3,56(sp)
    800018ba:	7a42                	ld	s4,48(sp)
    800018bc:	7aa2                	ld	s5,40(sp)
    800018be:	7b02                	ld	s6,32(sp)
    800018c0:	6be2                	ld	s7,24(sp)
    800018c2:	6c42                	ld	s8,16(sp)
    800018c4:	6ca2                	ld	s9,8(sp)
    800018c6:	6125                	addi	sp,sp,96
    800018c8:	8082                	ret
      return -1;
    800018ca:	557d                	li	a0,-1
    800018cc:	b7d5                	j	800018b0 <copyout+0xa2>

00000000800018ce <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    800018ce:	caa5                	beqz	a3,8000193e <copyin+0x70>
{
    800018d0:	715d                	addi	sp,sp,-80
    800018d2:	e486                	sd	ra,72(sp)
    800018d4:	e0a2                	sd	s0,64(sp)
    800018d6:	fc26                	sd	s1,56(sp)
    800018d8:	f84a                	sd	s2,48(sp)
    800018da:	f44e                	sd	s3,40(sp)
    800018dc:	f052                	sd	s4,32(sp)
    800018de:	ec56                	sd	s5,24(sp)
    800018e0:	e85a                	sd	s6,16(sp)
    800018e2:	e45e                	sd	s7,8(sp)
    800018e4:	e062                	sd	s8,0(sp)
    800018e6:	0880                	addi	s0,sp,80
    800018e8:	8b2a                	mv	s6,a0
    800018ea:	8a2e                	mv	s4,a1
    800018ec:	8c32                	mv	s8,a2
    800018ee:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800018f0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f2:	6a85                	lui	s5,0x1
    800018f4:	a01d                	j	8000191a <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018f6:	018505b3          	add	a1,a0,s8
    800018fa:	0004861b          	sext.w	a2,s1
    800018fe:	412585b3          	sub	a1,a1,s2
    80001902:	8552                	mv	a0,s4
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	5d6080e7          	jalr	1494(ra) # 80000eda <memmove>

    len -= n;
    8000190c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001910:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001912:	01590c33          	add	s8,s2,s5
  while (len > 0)
    80001916:	02098263          	beqz	s3,8000193a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000191a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000191e:	85ca                	mv	a1,s2
    80001920:	855a                	mv	a0,s6
    80001922:	00000097          	auipc	ra,0x0
    80001926:	8e6080e7          	jalr	-1818(ra) # 80001208 <walkaddr>
    if (pa0 == 0)
    8000192a:	cd01                	beqz	a0,80001942 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000192c:	418904b3          	sub	s1,s2,s8
    80001930:	94d6                	add	s1,s1,s5
    80001932:	fc99f2e3          	bgeu	s3,s1,800018f6 <copyin+0x28>
    80001936:	84ce                	mv	s1,s3
    80001938:	bf7d                	j	800018f6 <copyin+0x28>
  }
  return 0;
    8000193a:	4501                	li	a0,0
    8000193c:	a021                	j	80001944 <copyin+0x76>
    8000193e:	4501                	li	a0,0
}
    80001940:	8082                	ret
      return -1;
    80001942:	557d                	li	a0,-1
}
    80001944:	60a6                	ld	ra,72(sp)
    80001946:	6406                	ld	s0,64(sp)
    80001948:	74e2                	ld	s1,56(sp)
    8000194a:	7942                	ld	s2,48(sp)
    8000194c:	79a2                	ld	s3,40(sp)
    8000194e:	7a02                	ld	s4,32(sp)
    80001950:	6ae2                	ld	s5,24(sp)
    80001952:	6b42                	ld	s6,16(sp)
    80001954:	6ba2                	ld	s7,8(sp)
    80001956:	6c02                	ld	s8,0(sp)
    80001958:	6161                	addi	sp,sp,80
    8000195a:	8082                	ret

000000008000195c <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    8000195c:	c2dd                	beqz	a3,80001a02 <copyinstr+0xa6>
{
    8000195e:	715d                	addi	sp,sp,-80
    80001960:	e486                	sd	ra,72(sp)
    80001962:	e0a2                	sd	s0,64(sp)
    80001964:	fc26                	sd	s1,56(sp)
    80001966:	f84a                	sd	s2,48(sp)
    80001968:	f44e                	sd	s3,40(sp)
    8000196a:	f052                	sd	s4,32(sp)
    8000196c:	ec56                	sd	s5,24(sp)
    8000196e:	e85a                	sd	s6,16(sp)
    80001970:	e45e                	sd	s7,8(sp)
    80001972:	0880                	addi	s0,sp,80
    80001974:	8a2a                	mv	s4,a0
    80001976:	8b2e                	mv	s6,a1
    80001978:	8bb2                	mv	s7,a2
    8000197a:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    8000197c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000197e:	6985                	lui	s3,0x1
    80001980:	a02d                	j	800019aa <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001982:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001986:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001988:	37fd                	addiw	a5,a5,-1
    8000198a:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    8000198e:	60a6                	ld	ra,72(sp)
    80001990:	6406                	ld	s0,64(sp)
    80001992:	74e2                	ld	s1,56(sp)
    80001994:	7942                	ld	s2,48(sp)
    80001996:	79a2                	ld	s3,40(sp)
    80001998:	7a02                	ld	s4,32(sp)
    8000199a:	6ae2                	ld	s5,24(sp)
    8000199c:	6b42                	ld	s6,16(sp)
    8000199e:	6ba2                	ld	s7,8(sp)
    800019a0:	6161                	addi	sp,sp,80
    800019a2:	8082                	ret
    srcva = va0 + PGSIZE;
    800019a4:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    800019a8:	c8a9                	beqz	s1,800019fa <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800019aa:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019ae:	85ca                	mv	a1,s2
    800019b0:	8552                	mv	a0,s4
    800019b2:	00000097          	auipc	ra,0x0
    800019b6:	856080e7          	jalr	-1962(ra) # 80001208 <walkaddr>
    if (pa0 == 0)
    800019ba:	c131                	beqz	a0,800019fe <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800019bc:	417906b3          	sub	a3,s2,s7
    800019c0:	96ce                	add	a3,a3,s3
    800019c2:	00d4f363          	bgeu	s1,a3,800019c8 <copyinstr+0x6c>
    800019c6:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    800019c8:	955e                	add	a0,a0,s7
    800019ca:	41250533          	sub	a0,a0,s2
    while (n > 0)
    800019ce:	daf9                	beqz	a3,800019a4 <copyinstr+0x48>
    800019d0:	87da                	mv	a5,s6
      if (*p == '\0')
    800019d2:	41650633          	sub	a2,a0,s6
    800019d6:	fff48593          	addi	a1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdbc16f>
    800019da:	95da                	add	a1,a1,s6
    while (n > 0)
    800019dc:	96da                	add	a3,a3,s6
      if (*p == '\0')
    800019de:	00f60733          	add	a4,a2,a5
    800019e2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbc170>
    800019e6:	df51                	beqz	a4,80001982 <copyinstr+0x26>
        *dst = *p;
    800019e8:	00e78023          	sb	a4,0(a5)
      --max;
    800019ec:	40f584b3          	sub	s1,a1,a5
      dst++;
    800019f0:	0785                	addi	a5,a5,1
    while (n > 0)
    800019f2:	fed796e3          	bne	a5,a3,800019de <copyinstr+0x82>
      dst++;
    800019f6:	8b3e                	mv	s6,a5
    800019f8:	b775                	j	800019a4 <copyinstr+0x48>
    800019fa:	4781                	li	a5,0
    800019fc:	b771                	j	80001988 <copyinstr+0x2c>
      return -1;
    800019fe:	557d                	li	a0,-1
    80001a00:	b779                	j	8000198e <copyinstr+0x32>
  int got_null = 0;
    80001a02:	4781                	li	a5,0
  if (got_null)
    80001a04:	37fd                	addiw	a5,a5,-1
    80001a06:	0007851b          	sext.w	a0,a5
}
    80001a0a:	8082                	ret

0000000080001a0c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a0c:	7139                	addi	sp,sp,-64
    80001a0e:	fc06                	sd	ra,56(sp)
    80001a10:	f822                	sd	s0,48(sp)
    80001a12:	f426                	sd	s1,40(sp)
    80001a14:	f04a                	sd	s2,32(sp)
    80001a16:	ec4e                	sd	s3,24(sp)
    80001a18:	e852                	sd	s4,16(sp)
    80001a1a:	e456                	sd	s5,8(sp)
    80001a1c:	e05a                	sd	s6,0(sp)
    80001a1e:	0080                	addi	s0,sp,64
    80001a20:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a22:	00230497          	auipc	s1,0x230
    80001a26:	88e48493          	addi	s1,s1,-1906 # 802312b0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a2a:	8b26                	mv	s6,s1
    80001a2c:	00006a97          	auipc	s5,0x6
    80001a30:	5d4a8a93          	addi	s5,s5,1492 # 80008000 <etext>
    80001a34:	04000937          	lui	s2,0x4000
    80001a38:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a3a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a3c:	00236a17          	auipc	s4,0x236
    80001a40:	074a0a13          	addi	s4,s4,116 # 80237ab0 <tickslock>
    char *pa = kalloc();
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	210080e7          	jalr	528(ra) # 80000c54 <kalloc>
    80001a4c:	862a                	mv	a2,a0
    if (pa == 0)
    80001a4e:	c131                	beqz	a0,80001a92 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a50:	416485b3          	sub	a1,s1,s6
    80001a54:	8595                	srai	a1,a1,0x5
    80001a56:	000ab783          	ld	a5,0(s5)
    80001a5a:	02f585b3          	mul	a1,a1,a5
    80001a5e:	2585                	addiw	a1,a1,1
    80001a60:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a64:	4719                	li	a4,6
    80001a66:	6685                	lui	a3,0x1
    80001a68:	40b905b3          	sub	a1,s2,a1
    80001a6c:	854e                	mv	a0,s3
    80001a6e:	00000097          	auipc	ra,0x0
    80001a72:	87c080e7          	jalr	-1924(ra) # 800012ea <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a76:	1a048493          	addi	s1,s1,416
    80001a7a:	fd4495e3          	bne	s1,s4,80001a44 <proc_mapstacks+0x38>
  }
}
    80001a7e:	70e2                	ld	ra,56(sp)
    80001a80:	7442                	ld	s0,48(sp)
    80001a82:	74a2                	ld	s1,40(sp)
    80001a84:	7902                	ld	s2,32(sp)
    80001a86:	69e2                	ld	s3,24(sp)
    80001a88:	6a42                	ld	s4,16(sp)
    80001a8a:	6aa2                	ld	s5,8(sp)
    80001a8c:	6b02                	ld	s6,0(sp)
    80001a8e:	6121                	addi	sp,sp,64
    80001a90:	8082                	ret
      panic("kalloc");
    80001a92:	00006517          	auipc	a0,0x6
    80001a96:	76e50513          	addi	a0,a0,1902 # 80008200 <digits+0x1c0>
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	aa6080e7          	jalr	-1370(ra) # 80000540 <panic>

0000000080001aa2 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001aa2:	7139                	addi	sp,sp,-64
    80001aa4:	fc06                	sd	ra,56(sp)
    80001aa6:	f822                	sd	s0,48(sp)
    80001aa8:	f426                	sd	s1,40(sp)
    80001aaa:	f04a                	sd	s2,32(sp)
    80001aac:	ec4e                	sd	s3,24(sp)
    80001aae:	e852                	sd	s4,16(sp)
    80001ab0:	e456                	sd	s5,8(sp)
    80001ab2:	e05a                	sd	s6,0(sp)
    80001ab4:	0080                	addi	s0,sp,64
  // srand(time(NULL));

  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001ab6:	00006597          	auipc	a1,0x6
    80001aba:	75258593          	addi	a1,a1,1874 # 80008208 <digits+0x1c8>
    80001abe:	0022f517          	auipc	a0,0x22f
    80001ac2:	3c250513          	addi	a0,a0,962 # 80230e80 <pid_lock>
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	22c080e7          	jalr	556(ra) # 80000cf2 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ace:	00006597          	auipc	a1,0x6
    80001ad2:	74258593          	addi	a1,a1,1858 # 80008210 <digits+0x1d0>
    80001ad6:	0022f517          	auipc	a0,0x22f
    80001ada:	3c250513          	addi	a0,a0,962 # 80230e98 <wait_lock>
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	214080e7          	jalr	532(ra) # 80000cf2 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001ae6:	0022f497          	auipc	s1,0x22f
    80001aea:	7ca48493          	addi	s1,s1,1994 # 802312b0 <proc>
  {
    initlock(&p->lock, "proc");
    80001aee:	00006b17          	auipc	s6,0x6
    80001af2:	732b0b13          	addi	s6,s6,1842 # 80008220 <digits+0x1e0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001af6:	8aa6                	mv	s5,s1
    80001af8:	00006a17          	auipc	s4,0x6
    80001afc:	508a0a13          	addi	s4,s4,1288 # 80008000 <etext>
    80001b00:	04000937          	lui	s2,0x4000
    80001b04:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b06:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b08:	00236997          	auipc	s3,0x236
    80001b0c:	fa898993          	addi	s3,s3,-88 # 80237ab0 <tickslock>
    initlock(&p->lock, "proc");
    80001b10:	85da                	mv	a1,s6
    80001b12:	8526                	mv	a0,s1
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	1de080e7          	jalr	478(ra) # 80000cf2 <initlock>
    p->state = UNUSED;
    80001b1c:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b20:	415487b3          	sub	a5,s1,s5
    80001b24:	8795                	srai	a5,a5,0x5
    80001b26:	000a3703          	ld	a4,0(s4)
    80001b2a:	02e787b3          	mul	a5,a5,a4
    80001b2e:	2785                	addiw	a5,a5,1
    80001b30:	00d7979b          	slliw	a5,a5,0xd
    80001b34:	40f907b3          	sub	a5,s2,a5
    80001b38:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b3a:	1a048493          	addi	s1,s1,416
    80001b3e:	fd3499e3          	bne	s1,s3,80001b10 <procinit+0x6e>
  }
}
    80001b42:	70e2                	ld	ra,56(sp)
    80001b44:	7442                	ld	s0,48(sp)
    80001b46:	74a2                	ld	s1,40(sp)
    80001b48:	7902                	ld	s2,32(sp)
    80001b4a:	69e2                	ld	s3,24(sp)
    80001b4c:	6a42                	ld	s4,16(sp)
    80001b4e:	6aa2                	ld	s5,8(sp)
    80001b50:	6b02                	ld	s6,0(sp)
    80001b52:	6121                	addi	sp,sp,64
    80001b54:	8082                	ret

0000000080001b56 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b56:	1141                	addi	sp,sp,-16
    80001b58:	e422                	sd	s0,8(sp)
    80001b5a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b5c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b5e:	2501                	sext.w	a0,a0
    80001b60:	6422                	ld	s0,8(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret

0000000080001b66 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b66:	1141                	addi	sp,sp,-16
    80001b68:	e422                	sd	s0,8(sp)
    80001b6a:	0800                	addi	s0,sp,16
    80001b6c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b6e:	2781                	sext.w	a5,a5
    80001b70:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b72:	0022f517          	auipc	a0,0x22f
    80001b76:	33e50513          	addi	a0,a0,830 # 80230eb0 <cpus>
    80001b7a:	953e                	add	a0,a0,a5
    80001b7c:	6422                	ld	s0,8(sp)
    80001b7e:	0141                	addi	sp,sp,16
    80001b80:	8082                	ret

0000000080001b82 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b82:	1101                	addi	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	1000                	addi	s0,sp,32
  push_off();
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	1aa080e7          	jalr	426(ra) # 80000d36 <push_off>
    80001b94:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b96:	2781                	sext.w	a5,a5
    80001b98:	079e                	slli	a5,a5,0x7
    80001b9a:	0022f717          	auipc	a4,0x22f
    80001b9e:	2e670713          	addi	a4,a4,742 # 80230e80 <pid_lock>
    80001ba2:	97ba                	add	a5,a5,a4
    80001ba4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	230080e7          	jalr	560(ra) # 80000dd6 <pop_off>
  return p;
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bba:	1141                	addi	sp,sp,-16
    80001bbc:	e406                	sd	ra,8(sp)
    80001bbe:	e022                	sd	s0,0(sp)
    80001bc0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	fc0080e7          	jalr	-64(ra) # 80001b82 <myproc>
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	26c080e7          	jalr	620(ra) # 80000e36 <release>

  if (first)
    80001bd2:	00007797          	auipc	a5,0x7
    80001bd6:	f9e7a783          	lw	a5,-98(a5) # 80008b70 <first.1>
    80001bda:	eb89                	bnez	a5,80001bec <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bdc:	00001097          	auipc	ra,0x1
    80001be0:	e62080e7          	jalr	-414(ra) # 80002a3e <usertrapret>
}
    80001be4:	60a2                	ld	ra,8(sp)
    80001be6:	6402                	ld	s0,0(sp)
    80001be8:	0141                	addi	sp,sp,16
    80001bea:	8082                	ret
    first = 0;
    80001bec:	00007797          	auipc	a5,0x7
    80001bf0:	f807a223          	sw	zero,-124(a5) # 80008b70 <first.1>
    fsinit(ROOTDEV);
    80001bf4:	4505                	li	a0,1
    80001bf6:	00002097          	auipc	ra,0x2
    80001bfa:	f44080e7          	jalr	-188(ra) # 80003b3a <fsinit>
    80001bfe:	bff9                	j	80001bdc <forkret+0x22>

0000000080001c00 <allocpid>:
{
    80001c00:	1101                	addi	sp,sp,-32
    80001c02:	ec06                	sd	ra,24(sp)
    80001c04:	e822                	sd	s0,16(sp)
    80001c06:	e426                	sd	s1,8(sp)
    80001c08:	e04a                	sd	s2,0(sp)
    80001c0a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c0c:	0022f917          	auipc	s2,0x22f
    80001c10:	27490913          	addi	s2,s2,628 # 80230e80 <pid_lock>
    80001c14:	854a                	mv	a0,s2
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	16c080e7          	jalr	364(ra) # 80000d82 <acquire>
  pid = nextpid;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	f5678793          	addi	a5,a5,-170 # 80008b74 <nextpid>
    80001c26:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c28:	0014871b          	addiw	a4,s1,1
    80001c2c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c2e:	854a                	mv	a0,s2
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	206080e7          	jalr	518(ra) # 80000e36 <release>
}
    80001c38:	8526                	mv	a0,s1
    80001c3a:	60e2                	ld	ra,24(sp)
    80001c3c:	6442                	ld	s0,16(sp)
    80001c3e:	64a2                	ld	s1,8(sp)
    80001c40:	6902                	ld	s2,0(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret

0000000080001c46 <proc_pagetable>:
{
    80001c46:	1101                	addi	sp,sp,-32
    80001c48:	ec06                	sd	ra,24(sp)
    80001c4a:	e822                	sd	s0,16(sp)
    80001c4c:	e426                	sd	s1,8(sp)
    80001c4e:	e04a                	sd	s2,0(sp)
    80001c50:	1000                	addi	s0,sp,32
    80001c52:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c54:	00000097          	auipc	ra,0x0
    80001c58:	880080e7          	jalr	-1920(ra) # 800014d4 <uvmcreate>
    80001c5c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c5e:	c121                	beqz	a0,80001c9e <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c60:	4729                	li	a4,10
    80001c62:	00005697          	auipc	a3,0x5
    80001c66:	39e68693          	addi	a3,a3,926 # 80007000 <_trampoline>
    80001c6a:	6605                	lui	a2,0x1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c72:	05b2                	slli	a1,a1,0xc
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	5d6080e7          	jalr	1494(ra) # 8000124a <mappages>
    80001c7c:	02054863          	bltz	a0,80001cac <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c80:	4719                	li	a4,6
    80001c82:	05893683          	ld	a3,88(s2)
    80001c86:	6605                	lui	a2,0x1
    80001c88:	020005b7          	lui	a1,0x2000
    80001c8c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c8e:	05b6                	slli	a1,a1,0xd
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	5b8080e7          	jalr	1464(ra) # 8000124a <mappages>
    80001c9a:	02054163          	bltz	a0,80001cbc <proc_pagetable+0x76>
}
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	60e2                	ld	ra,24(sp)
    80001ca2:	6442                	ld	s0,16(sp)
    80001ca4:	64a2                	ld	s1,8(sp)
    80001ca6:	6902                	ld	s2,0(sp)
    80001ca8:	6105                	addi	sp,sp,32
    80001caa:	8082                	ret
    uvmfree(pagetable, 0);
    80001cac:	4581                	li	a1,0
    80001cae:	8526                	mv	a0,s1
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	a2a080e7          	jalr	-1494(ra) # 800016da <uvmfree>
    return 0;
    80001cb8:	4481                	li	s1,0
    80001cba:	b7d5                	j	80001c9e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cbc:	4681                	li	a3,0
    80001cbe:	4605                	li	a2,1
    80001cc0:	040005b7          	lui	a1,0x4000
    80001cc4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cc6:	05b2                	slli	a1,a1,0xc
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	746080e7          	jalr	1862(ra) # 80001410 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cd2:	4581                	li	a1,0
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	a04080e7          	jalr	-1532(ra) # 800016da <uvmfree>
    return 0;
    80001cde:	4481                	li	s1,0
    80001ce0:	bf7d                	j	80001c9e <proc_pagetable+0x58>

0000000080001ce2 <proc_freepagetable>:
{
    80001ce2:	1101                	addi	sp,sp,-32
    80001ce4:	ec06                	sd	ra,24(sp)
    80001ce6:	e822                	sd	s0,16(sp)
    80001ce8:	e426                	sd	s1,8(sp)
    80001cea:	e04a                	sd	s2,0(sp)
    80001cec:	1000                	addi	s0,sp,32
    80001cee:	84aa                	mv	s1,a0
    80001cf0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cf2:	4681                	li	a3,0
    80001cf4:	4605                	li	a2,1
    80001cf6:	040005b7          	lui	a1,0x4000
    80001cfa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cfc:	05b2                	slli	a1,a1,0xc
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	712080e7          	jalr	1810(ra) # 80001410 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d06:	4681                	li	a3,0
    80001d08:	4605                	li	a2,1
    80001d0a:	020005b7          	lui	a1,0x2000
    80001d0e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d10:	05b6                	slli	a1,a1,0xd
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	6fc080e7          	jalr	1788(ra) # 80001410 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d1c:	85ca                	mv	a1,s2
    80001d1e:	8526                	mv	a0,s1
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	9ba080e7          	jalr	-1606(ra) # 800016da <uvmfree>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6902                	ld	s2,0(sp)
    80001d30:	6105                	addi	sp,sp,32
    80001d32:	8082                	ret

0000000080001d34 <freeproc>:
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	1000                	addi	s0,sp,32
    80001d3e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d40:	6d28                	ld	a0,88(a0)
    80001d42:	c509                	beqz	a0,80001d4c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	d70080e7          	jalr	-656(ra) # 80000ab4 <kfree>
  p->trapframe = 0;
    80001d4c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d50:	68a8                	ld	a0,80(s1)
    80001d52:	c511                	beqz	a0,80001d5e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d54:	64ac                	ld	a1,72(s1)
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	f8c080e7          	jalr	-116(ra) # 80001ce2 <proc_freepagetable>
  p->pagetable = 0;
    80001d5e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d62:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d66:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d6a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d6e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d72:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d76:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d7a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d7e:	0004ac23          	sw	zero,24(s1)
}
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret

0000000080001d8c <allocproc>:
{
    80001d8c:	1101                	addi	sp,sp,-32
    80001d8e:	ec06                	sd	ra,24(sp)
    80001d90:	e822                	sd	s0,16(sp)
    80001d92:	e426                	sd	s1,8(sp)
    80001d94:	e04a                	sd	s2,0(sp)
    80001d96:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d98:	0022f497          	auipc	s1,0x22f
    80001d9c:	51848493          	addi	s1,s1,1304 # 802312b0 <proc>
    80001da0:	00236917          	auipc	s2,0x236
    80001da4:	d1090913          	addi	s2,s2,-752 # 80237ab0 <tickslock>
    acquire(&p->lock);
    80001da8:	8526                	mv	a0,s1
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	fd8080e7          	jalr	-40(ra) # 80000d82 <acquire>
    if (p->state == UNUSED)
    80001db2:	4c9c                	lw	a5,24(s1)
    80001db4:	cf81                	beqz	a5,80001dcc <allocproc+0x40>
      release(&p->lock);
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	07e080e7          	jalr	126(ra) # 80000e36 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dc0:	1a048493          	addi	s1,s1,416
    80001dc4:	ff2492e3          	bne	s1,s2,80001da8 <allocproc+0x1c>
  return 0;
    80001dc8:	4481                	li	s1,0
    80001dca:	a8bd                	j	80001e48 <allocproc+0xbc>
  p->pid = allocpid();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	e34080e7          	jalr	-460(ra) # 80001c00 <allocpid>
    80001dd4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001dd6:	4785                	li	a5,1
    80001dd8:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	e7a080e7          	jalr	-390(ra) # 80000c54 <kalloc>
    80001de2:	892a                	mv	s2,a0
    80001de4:	eca8                	sd	a0,88(s1)
    80001de6:	c925                	beqz	a0,80001e56 <allocproc+0xca>
  p->pagetable = proc_pagetable(p);
    80001de8:	8526                	mv	a0,s1
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	e5c080e7          	jalr	-420(ra) # 80001c46 <proc_pagetable>
    80001df2:	892a                	mv	s2,a0
    80001df4:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001df6:	cd25                	beqz	a0,80001e6e <allocproc+0xe2>
  memset(&p->context, 0, sizeof(p->context));
    80001df8:	07000613          	li	a2,112
    80001dfc:	4581                	li	a1,0
    80001dfe:	06048513          	addi	a0,s1,96
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	07c080e7          	jalr	124(ra) # 80000e7e <memset>
  p->context.ra = (uint64)forkret;
    80001e0a:	00000797          	auipc	a5,0x0
    80001e0e:	db078793          	addi	a5,a5,-592 # 80001bba <forkret>
    80001e12:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e14:	60bc                	ld	a5,64(s1)
    80001e16:	6705                	lui	a4,0x1
    80001e18:	97ba                	add	a5,a5,a4
    80001e1a:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e1c:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e20:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e24:	00007797          	auipc	a5,0x7
    80001e28:	dec7a783          	lw	a5,-532(a5) # 80008c10 <ticks>
    80001e2c:	16f4a623          	sw	a5,364(s1)
  p->alarmticks = 0;
    80001e30:	1604ac23          	sw	zero,376(s1)
  p->currentticks = 0;
    80001e34:	1604ae23          	sw	zero,380(s1)
  p->alarmset = 0;
    80001e38:	1804a023          	sw	zero,384(s1)
  p->alarm_called = 0;
    80001e3c:	1804ac23          	sw	zero,408(s1)
  p->alarm_tf = 0;
    80001e40:	1804b423          	sd	zero,392(s1)
  p->handler = 0;
    80001e44:	1804b823          	sd	zero,400(s1)
}
    80001e48:	8526                	mv	a0,s1
    80001e4a:	60e2                	ld	ra,24(sp)
    80001e4c:	6442                	ld	s0,16(sp)
    80001e4e:	64a2                	ld	s1,8(sp)
    80001e50:	6902                	ld	s2,0(sp)
    80001e52:	6105                	addi	sp,sp,32
    80001e54:	8082                	ret
    freeproc(p);
    80001e56:	8526                	mv	a0,s1
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	edc080e7          	jalr	-292(ra) # 80001d34 <freeproc>
    release(&p->lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	fd4080e7          	jalr	-44(ra) # 80000e36 <release>
    return 0;
    80001e6a:	84ca                	mv	s1,s2
    80001e6c:	bff1                	j	80001e48 <allocproc+0xbc>
    freeproc(p);
    80001e6e:	8526                	mv	a0,s1
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	ec4080e7          	jalr	-316(ra) # 80001d34 <freeproc>
    release(&p->lock);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fbc080e7          	jalr	-68(ra) # 80000e36 <release>
    return 0;
    80001e82:	84ca                	mv	s1,s2
    80001e84:	b7d1                	j	80001e48 <allocproc+0xbc>

0000000080001e86 <userinit>:
{
    80001e86:	1101                	addi	sp,sp,-32
    80001e88:	ec06                	sd	ra,24(sp)
    80001e8a:	e822                	sd	s0,16(sp)
    80001e8c:	e426                	sd	s1,8(sp)
    80001e8e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e90:	00000097          	auipc	ra,0x0
    80001e94:	efc080e7          	jalr	-260(ra) # 80001d8c <allocproc>
    80001e98:	84aa                	mv	s1,a0
  initproc = p;
    80001e9a:	00007797          	auipc	a5,0x7
    80001e9e:	d6a7b723          	sd	a0,-658(a5) # 80008c08 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ea2:	03400613          	li	a2,52
    80001ea6:	00007597          	auipc	a1,0x7
    80001eaa:	cda58593          	addi	a1,a1,-806 # 80008b80 <initcode>
    80001eae:	6928                	ld	a0,80(a0)
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	652080e7          	jalr	1618(ra) # 80001502 <uvmfirst>
  p->sz = PGSIZE;
    80001eb8:	6785                	lui	a5,0x1
    80001eba:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ebc:	6cb8                	ld	a4,88(s1)
    80001ebe:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ec2:	6cb8                	ld	a4,88(s1)
    80001ec4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ec6:	4641                	li	a2,16
    80001ec8:	00006597          	auipc	a1,0x6
    80001ecc:	36058593          	addi	a1,a1,864 # 80008228 <digits+0x1e8>
    80001ed0:	15848513          	addi	a0,s1,344
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	0f4080e7          	jalr	244(ra) # 80000fc8 <safestrcpy>
  p->cwd = namei("/");
    80001edc:	00006517          	auipc	a0,0x6
    80001ee0:	35c50513          	addi	a0,a0,860 # 80008238 <digits+0x1f8>
    80001ee4:	00002097          	auipc	ra,0x2
    80001ee8:	680080e7          	jalr	1664(ra) # 80004564 <namei>
    80001eec:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ef0:	478d                	li	a5,3
    80001ef2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	f40080e7          	jalr	-192(ra) # 80000e36 <release>
}
    80001efe:	60e2                	ld	ra,24(sp)
    80001f00:	6442                	ld	s0,16(sp)
    80001f02:	64a2                	ld	s1,8(sp)
    80001f04:	6105                	addi	sp,sp,32
    80001f06:	8082                	ret

0000000080001f08 <growproc>:
{
    80001f08:	1101                	addi	sp,sp,-32
    80001f0a:	ec06                	sd	ra,24(sp)
    80001f0c:	e822                	sd	s0,16(sp)
    80001f0e:	e426                	sd	s1,8(sp)
    80001f10:	e04a                	sd	s2,0(sp)
    80001f12:	1000                	addi	s0,sp,32
    80001f14:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	c6c080e7          	jalr	-916(ra) # 80001b82 <myproc>
    80001f1e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f20:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f22:	01204c63          	bgtz	s2,80001f3a <growproc+0x32>
  else if (n < 0)
    80001f26:	02094663          	bltz	s2,80001f52 <growproc+0x4a>
  p->sz = sz;
    80001f2a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f2c:	4501                	li	a0,0
}
    80001f2e:	60e2                	ld	ra,24(sp)
    80001f30:	6442                	ld	s0,16(sp)
    80001f32:	64a2                	ld	s1,8(sp)
    80001f34:	6902                	ld	s2,0(sp)
    80001f36:	6105                	addi	sp,sp,32
    80001f38:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f3a:	4691                	li	a3,4
    80001f3c:	00b90633          	add	a2,s2,a1
    80001f40:	6928                	ld	a0,80(a0)
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	67a080e7          	jalr	1658(ra) # 800015bc <uvmalloc>
    80001f4a:	85aa                	mv	a1,a0
    80001f4c:	fd79                	bnez	a0,80001f2a <growproc+0x22>
      return -1;
    80001f4e:	557d                	li	a0,-1
    80001f50:	bff9                	j	80001f2e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f52:	00b90633          	add	a2,s2,a1
    80001f56:	6928                	ld	a0,80(a0)
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	61c080e7          	jalr	1564(ra) # 80001574 <uvmdealloc>
    80001f60:	85aa                	mv	a1,a0
    80001f62:	b7e1                	j	80001f2a <growproc+0x22>

0000000080001f64 <fork>:
{
    80001f64:	7139                	addi	sp,sp,-64
    80001f66:	fc06                	sd	ra,56(sp)
    80001f68:	f822                	sd	s0,48(sp)
    80001f6a:	f426                	sd	s1,40(sp)
    80001f6c:	f04a                	sd	s2,32(sp)
    80001f6e:	ec4e                	sd	s3,24(sp)
    80001f70:	e852                	sd	s4,16(sp)
    80001f72:	e456                	sd	s5,8(sp)
    80001f74:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	c0c080e7          	jalr	-1012(ra) # 80001b82 <myproc>
    80001f7e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	e0c080e7          	jalr	-500(ra) # 80001d8c <allocproc>
    80001f88:	12050063          	beqz	a0,800020a8 <fork+0x144>
    80001f8c:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f8e:	048ab603          	ld	a2,72(s5)
    80001f92:	692c                	ld	a1,80(a0)
    80001f94:	050ab503          	ld	a0,80(s5)
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	77c080e7          	jalr	1916(ra) # 80001714 <uvmcopy>
    80001fa0:	04054c63          	bltz	a0,80001ff8 <fork+0x94>
  np->sz = p->sz;
    80001fa4:	048ab783          	ld	a5,72(s5)
    80001fa8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fac:	058ab683          	ld	a3,88(s5)
    80001fb0:	87b6                	mv	a5,a3
    80001fb2:	0589b703          	ld	a4,88(s3)
    80001fb6:	12068693          	addi	a3,a3,288
    80001fba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fbe:	6788                	ld	a0,8(a5)
    80001fc0:	6b8c                	ld	a1,16(a5)
    80001fc2:	6f90                	ld	a2,24(a5)
    80001fc4:	01073023          	sd	a6,0(a4)
    80001fc8:	e708                	sd	a0,8(a4)
    80001fca:	eb0c                	sd	a1,16(a4)
    80001fcc:	ef10                	sd	a2,24(a4)
    80001fce:	02078793          	addi	a5,a5,32
    80001fd2:	02070713          	addi	a4,a4,32
    80001fd6:	fed792e3          	bne	a5,a3,80001fba <fork+0x56>
  np->trapframe->a0 = 0;
    80001fda:	0589b783          	ld	a5,88(s3)
    80001fde:	0607b823          	sd	zero,112(a5)
  np->mask = p->mask;
    80001fe2:	174aa783          	lw	a5,372(s5)
    80001fe6:	16f9aa23          	sw	a5,372(s3)
  for (i = 0; i < NOFILE; i++)
    80001fea:	0d0a8493          	addi	s1,s5,208
    80001fee:	0d098913          	addi	s2,s3,208
    80001ff2:	150a8a13          	addi	s4,s5,336
    80001ff6:	a00d                	j	80002018 <fork+0xb4>
    freeproc(np);
    80001ff8:	854e                	mv	a0,s3
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	d3a080e7          	jalr	-710(ra) # 80001d34 <freeproc>
    release(&np->lock);
    80002002:	854e                	mv	a0,s3
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	e32080e7          	jalr	-462(ra) # 80000e36 <release>
    return -1;
    8000200c:	597d                	li	s2,-1
    8000200e:	a059                	j	80002094 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80002010:	04a1                	addi	s1,s1,8
    80002012:	0921                	addi	s2,s2,8
    80002014:	01448b63          	beq	s1,s4,8000202a <fork+0xc6>
    if (p->ofile[i])
    80002018:	6088                	ld	a0,0(s1)
    8000201a:	d97d                	beqz	a0,80002010 <fork+0xac>
      np->ofile[i] = filedup(p->ofile[i]);
    8000201c:	00003097          	auipc	ra,0x3
    80002020:	bde080e7          	jalr	-1058(ra) # 80004bfa <filedup>
    80002024:	00a93023          	sd	a0,0(s2)
    80002028:	b7e5                	j	80002010 <fork+0xac>
  np->cwd = idup(p->cwd);
    8000202a:	150ab503          	ld	a0,336(s5)
    8000202e:	00002097          	auipc	ra,0x2
    80002032:	d4c080e7          	jalr	-692(ra) # 80003d7a <idup>
    80002036:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000203a:	4641                	li	a2,16
    8000203c:	158a8593          	addi	a1,s5,344
    80002040:	15898513          	addi	a0,s3,344
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	f84080e7          	jalr	-124(ra) # 80000fc8 <safestrcpy>
  pid = np->pid;
    8000204c:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002050:	854e                	mv	a0,s3
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	de4080e7          	jalr	-540(ra) # 80000e36 <release>
  acquire(&wait_lock);
    8000205a:	0022f497          	auipc	s1,0x22f
    8000205e:	e3e48493          	addi	s1,s1,-450 # 80230e98 <wait_lock>
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	d1e080e7          	jalr	-738(ra) # 80000d82 <acquire>
  np->parent = p;
    8000206c:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	dc4080e7          	jalr	-572(ra) # 80000e36 <release>
  acquire(&np->lock);
    8000207a:	854e                	mv	a0,s3
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	d06080e7          	jalr	-762(ra) # 80000d82 <acquire>
  np->state = RUNNABLE;
    80002084:	478d                	li	a5,3
    80002086:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000208a:	854e                	mv	a0,s3
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	daa080e7          	jalr	-598(ra) # 80000e36 <release>
}
    80002094:	854a                	mv	a0,s2
    80002096:	70e2                	ld	ra,56(sp)
    80002098:	7442                	ld	s0,48(sp)
    8000209a:	74a2                	ld	s1,40(sp)
    8000209c:	7902                	ld	s2,32(sp)
    8000209e:	69e2                	ld	s3,24(sp)
    800020a0:	6a42                	ld	s4,16(sp)
    800020a2:	6aa2                	ld	s5,8(sp)
    800020a4:	6121                	addi	sp,sp,64
    800020a6:	8082                	ret
    return -1;
    800020a8:	597d                	li	s2,-1
    800020aa:	b7ed                	j	80002094 <fork+0x130>

00000000800020ac <update_time>:
{
    800020ac:	7179                	addi	sp,sp,-48
    800020ae:	f406                	sd	ra,40(sp)
    800020b0:	f022                	sd	s0,32(sp)
    800020b2:	ec26                	sd	s1,24(sp)
    800020b4:	e84a                	sd	s2,16(sp)
    800020b6:	e44e                	sd	s3,8(sp)
    800020b8:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    800020ba:	0022f497          	auipc	s1,0x22f
    800020be:	1f648493          	addi	s1,s1,502 # 802312b0 <proc>
    if (p->state == RUNNING)
    800020c2:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800020c4:	00236917          	auipc	s2,0x236
    800020c8:	9ec90913          	addi	s2,s2,-1556 # 80237ab0 <tickslock>
    800020cc:	a811                	j	800020e0 <update_time+0x34>
    release(&p->lock);
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	d66080e7          	jalr	-666(ra) # 80000e36 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020d8:	1a048493          	addi	s1,s1,416
    800020dc:	03248063          	beq	s1,s2,800020fc <update_time+0x50>
    acquire(&p->lock);
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	ca0080e7          	jalr	-864(ra) # 80000d82 <acquire>
    if (p->state == RUNNING)
    800020ea:	4c9c                	lw	a5,24(s1)
    800020ec:	ff3791e3          	bne	a5,s3,800020ce <update_time+0x22>
      p->rtime++;
    800020f0:	1684a783          	lw	a5,360(s1)
    800020f4:	2785                	addiw	a5,a5,1
    800020f6:	16f4a423          	sw	a5,360(s1)
    800020fa:	bfd1                	j	800020ce <update_time+0x22>
}
    800020fc:	70a2                	ld	ra,40(sp)
    800020fe:	7402                	ld	s0,32(sp)
    80002100:	64e2                	ld	s1,24(sp)
    80002102:	6942                	ld	s2,16(sp)
    80002104:	69a2                	ld	s3,8(sp)
    80002106:	6145                	addi	sp,sp,48
    80002108:	8082                	ret

000000008000210a <scheduler>:
{
    8000210a:	7139                	addi	sp,sp,-64
    8000210c:	fc06                	sd	ra,56(sp)
    8000210e:	f822                	sd	s0,48(sp)
    80002110:	f426                	sd	s1,40(sp)
    80002112:	f04a                	sd	s2,32(sp)
    80002114:	ec4e                	sd	s3,24(sp)
    80002116:	e852                	sd	s4,16(sp)
    80002118:	e456                	sd	s5,8(sp)
    8000211a:	e05a                	sd	s6,0(sp)
    8000211c:	0080                	addi	s0,sp,64
    8000211e:	8792                	mv	a5,tp
  int id = r_tp();
    80002120:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002122:	00779a93          	slli	s5,a5,0x7
    80002126:	0022f717          	auipc	a4,0x22f
    8000212a:	d5a70713          	addi	a4,a4,-678 # 80230e80 <pid_lock>
    8000212e:	9756                	add	a4,a4,s5
    80002130:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002134:	0022f717          	auipc	a4,0x22f
    80002138:	d8470713          	addi	a4,a4,-636 # 80230eb8 <cpus+0x8>
    8000213c:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000213e:	498d                	li	s3,3
        p->state = RUNNING;
    80002140:	4b11                	li	s6,4
        c->proc = p;
    80002142:	079e                	slli	a5,a5,0x7
    80002144:	0022fa17          	auipc	s4,0x22f
    80002148:	d3ca0a13          	addi	s4,s4,-708 # 80230e80 <pid_lock>
    8000214c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000214e:	00236917          	auipc	s2,0x236
    80002152:	96290913          	addi	s2,s2,-1694 # 80237ab0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002156:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000215a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000215e:	10079073          	csrw	sstatus,a5
    80002162:	0022f497          	auipc	s1,0x22f
    80002166:	14e48493          	addi	s1,s1,334 # 802312b0 <proc>
    8000216a:	a811                	j	8000217e <scheduler+0x74>
      release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	cc8080e7          	jalr	-824(ra) # 80000e36 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002176:	1a048493          	addi	s1,s1,416
    8000217a:	fd248ee3          	beq	s1,s2,80002156 <scheduler+0x4c>
      acquire(&p->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	c02080e7          	jalr	-1022(ra) # 80000d82 <acquire>
      if (p->state == RUNNABLE)
    80002188:	4c9c                	lw	a5,24(s1)
    8000218a:	ff3791e3          	bne	a5,s3,8000216c <scheduler+0x62>
        p->state = RUNNING;
    8000218e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002192:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002196:	06048593          	addi	a1,s1,96
    8000219a:	8556                	mv	a0,s5
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	7f8080e7          	jalr	2040(ra) # 80002994 <swtch>
        c->proc = 0;
    800021a4:	020a3823          	sd	zero,48(s4)
    800021a8:	b7d1                	j	8000216c <scheduler+0x62>

00000000800021aa <sched>:
{
    800021aa:	7179                	addi	sp,sp,-48
    800021ac:	f406                	sd	ra,40(sp)
    800021ae:	f022                	sd	s0,32(sp)
    800021b0:	ec26                	sd	s1,24(sp)
    800021b2:	e84a                	sd	s2,16(sp)
    800021b4:	e44e                	sd	s3,8(sp)
    800021b6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021b8:	00000097          	auipc	ra,0x0
    800021bc:	9ca080e7          	jalr	-1590(ra) # 80001b82 <myproc>
    800021c0:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	b46080e7          	jalr	-1210(ra) # 80000d08 <holding>
    800021ca:	c93d                	beqz	a0,80002240 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021cc:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021ce:	2781                	sext.w	a5,a5
    800021d0:	079e                	slli	a5,a5,0x7
    800021d2:	0022f717          	auipc	a4,0x22f
    800021d6:	cae70713          	addi	a4,a4,-850 # 80230e80 <pid_lock>
    800021da:	97ba                	add	a5,a5,a4
    800021dc:	0a87a703          	lw	a4,168(a5)
    800021e0:	4785                	li	a5,1
    800021e2:	06f71763          	bne	a4,a5,80002250 <sched+0xa6>
  if (p->state == RUNNING)
    800021e6:	4c98                	lw	a4,24(s1)
    800021e8:	4791                	li	a5,4
    800021ea:	06f70b63          	beq	a4,a5,80002260 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021f2:	8b89                	andi	a5,a5,2
  if (intr_get())
    800021f4:	efb5                	bnez	a5,80002270 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021f8:	0022f917          	auipc	s2,0x22f
    800021fc:	c8890913          	addi	s2,s2,-888 # 80230e80 <pid_lock>
    80002200:	2781                	sext.w	a5,a5
    80002202:	079e                	slli	a5,a5,0x7
    80002204:	97ca                	add	a5,a5,s2
    80002206:	0ac7a983          	lw	s3,172(a5)
    8000220a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000220c:	2781                	sext.w	a5,a5
    8000220e:	079e                	slli	a5,a5,0x7
    80002210:	0022f597          	auipc	a1,0x22f
    80002214:	ca858593          	addi	a1,a1,-856 # 80230eb8 <cpus+0x8>
    80002218:	95be                	add	a1,a1,a5
    8000221a:	06048513          	addi	a0,s1,96
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	776080e7          	jalr	1910(ra) # 80002994 <swtch>
    80002226:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002228:	2781                	sext.w	a5,a5
    8000222a:	079e                	slli	a5,a5,0x7
    8000222c:	993e                	add	s2,s2,a5
    8000222e:	0b392623          	sw	s3,172(s2)
}
    80002232:	70a2                	ld	ra,40(sp)
    80002234:	7402                	ld	s0,32(sp)
    80002236:	64e2                	ld	s1,24(sp)
    80002238:	6942                	ld	s2,16(sp)
    8000223a:	69a2                	ld	s3,8(sp)
    8000223c:	6145                	addi	sp,sp,48
    8000223e:	8082                	ret
    panic("sched p->lock");
    80002240:	00006517          	auipc	a0,0x6
    80002244:	00050513          	mv	a0,a0
    80002248:	ffffe097          	auipc	ra,0xffffe
    8000224c:	2f8080e7          	jalr	760(ra) # 80000540 <panic>
    panic("sched locks");
    80002250:	00006517          	auipc	a0,0x6
    80002254:	00050513          	mv	a0,a0
    80002258:	ffffe097          	auipc	ra,0xffffe
    8000225c:	2e8080e7          	jalr	744(ra) # 80000540 <panic>
    panic("sched running");
    80002260:	00006517          	auipc	a0,0x6
    80002264:	00050513          	mv	a0,a0
    80002268:	ffffe097          	auipc	ra,0xffffe
    8000226c:	2d8080e7          	jalr	728(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002270:	00006517          	auipc	a0,0x6
    80002274:	00050513          	mv	a0,a0
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	2c8080e7          	jalr	712(ra) # 80000540 <panic>

0000000080002280 <yield>:
{
    80002280:	1101                	addi	sp,sp,-32
    80002282:	ec06                	sd	ra,24(sp)
    80002284:	e822                	sd	s0,16(sp)
    80002286:	e426                	sd	s1,8(sp)
    80002288:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000228a:	00000097          	auipc	ra,0x0
    8000228e:	8f8080e7          	jalr	-1800(ra) # 80001b82 <myproc>
    80002292:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	aee080e7          	jalr	-1298(ra) # 80000d82 <acquire>
  p->state = RUNNABLE;
    8000229c:	478d                	li	a5,3
    8000229e:	cc9c                	sw	a5,24(s1)
  sched();
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	f0a080e7          	jalr	-246(ra) # 800021aa <sched>
  release(&p->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	b8c080e7          	jalr	-1140(ra) # 80000e36 <release>
}
    800022b2:	60e2                	ld	ra,24(sp)
    800022b4:	6442                	ld	s0,16(sp)
    800022b6:	64a2                	ld	s1,8(sp)
    800022b8:	6105                	addi	sp,sp,32
    800022ba:	8082                	ret

00000000800022bc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022bc:	7179                	addi	sp,sp,-48
    800022be:	f406                	sd	ra,40(sp)
    800022c0:	f022                	sd	s0,32(sp)
    800022c2:	ec26                	sd	s1,24(sp)
    800022c4:	e84a                	sd	s2,16(sp)
    800022c6:	e44e                	sd	s3,8(sp)
    800022c8:	1800                	addi	s0,sp,48
    800022ca:	89aa                	mv	s3,a0
    800022cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	8b4080e7          	jalr	-1868(ra) # 80001b82 <myproc>
    800022d6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	aaa080e7          	jalr	-1366(ra) # 80000d82 <acquire>
  release(lk);
    800022e0:	854a                	mv	a0,s2
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	b54080e7          	jalr	-1196(ra) # 80000e36 <release>

  // Go to sleep.
  p->chan = chan;
    800022ea:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800022ee:	4789                	li	a5,2
    800022f0:	cc9c                	sw	a5,24(s1)
#ifdef PBS
  p->sleep_time = ticks;
  p->run_time = ticks - (p->run_time);
#endif

  sched();
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	eb8080e7          	jalr	-328(ra) # 800021aa <sched>

  // Tidy up.
  p->chan = 0;
    800022fa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	b36080e7          	jalr	-1226(ra) # 80000e36 <release>
  acquire(lk);
    80002308:	854a                	mv	a0,s2
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	a78080e7          	jalr	-1416(ra) # 80000d82 <acquire>
}
    80002312:	70a2                	ld	ra,40(sp)
    80002314:	7402                	ld	s0,32(sp)
    80002316:	64e2                	ld	s1,24(sp)
    80002318:	6942                	ld	s2,16(sp)
    8000231a:	69a2                	ld	s3,8(sp)
    8000231c:	6145                	addi	sp,sp,48
    8000231e:	8082                	ret

0000000080002320 <waitx>:
{
    80002320:	711d                	addi	sp,sp,-96
    80002322:	ec86                	sd	ra,88(sp)
    80002324:	e8a2                	sd	s0,80(sp)
    80002326:	e4a6                	sd	s1,72(sp)
    80002328:	e0ca                	sd	s2,64(sp)
    8000232a:	fc4e                	sd	s3,56(sp)
    8000232c:	f852                	sd	s4,48(sp)
    8000232e:	f456                	sd	s5,40(sp)
    80002330:	f05a                	sd	s6,32(sp)
    80002332:	ec5e                	sd	s7,24(sp)
    80002334:	e862                	sd	s8,16(sp)
    80002336:	e466                	sd	s9,8(sp)
    80002338:	e06a                	sd	s10,0(sp)
    8000233a:	1080                	addi	s0,sp,96
    8000233c:	8b2a                	mv	s6,a0
    8000233e:	8bae                	mv	s7,a1
    80002340:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	840080e7          	jalr	-1984(ra) # 80001b82 <myproc>
    8000234a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000234c:	0022f517          	auipc	a0,0x22f
    80002350:	b4c50513          	addi	a0,a0,-1204 # 80230e98 <wait_lock>
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	a2e080e7          	jalr	-1490(ra) # 80000d82 <acquire>
    havekids = 0;
    8000235c:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000235e:	4a15                	li	s4,5
        havekids = 1;
    80002360:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002362:	00235997          	auipc	s3,0x235
    80002366:	74e98993          	addi	s3,s3,1870 # 80237ab0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000236a:	0022fd17          	auipc	s10,0x22f
    8000236e:	b2ed0d13          	addi	s10,s10,-1234 # 80230e98 <wait_lock>
    havekids = 0;
    80002372:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002374:	0022f497          	auipc	s1,0x22f
    80002378:	f3c48493          	addi	s1,s1,-196 # 802312b0 <proc>
    8000237c:	a059                	j	80002402 <waitx+0xe2>
          pid = np->pid;
    8000237e:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002382:	1684a783          	lw	a5,360(s1)
    80002386:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000238a:	16c4a703          	lw	a4,364(s1)
    8000238e:	9f3d                	addw	a4,a4,a5
    80002390:	1704a783          	lw	a5,368(s1)
    80002394:	9f99                	subw	a5,a5,a4
    80002396:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7fdbc170>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000239a:	000b0e63          	beqz	s6,800023b6 <waitx+0x96>
    8000239e:	4691                	li	a3,4
    800023a0:	02c48613          	addi	a2,s1,44
    800023a4:	85da                	mv	a1,s6
    800023a6:	05093503          	ld	a0,80(s2)
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	464080e7          	jalr	1124(ra) # 8000180e <copyout>
    800023b2:	02054563          	bltz	a0,800023dc <waitx+0xbc>
          freeproc(np);
    800023b6:	8526                	mv	a0,s1
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	97c080e7          	jalr	-1668(ra) # 80001d34 <freeproc>
          release(&np->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	a74080e7          	jalr	-1420(ra) # 80000e36 <release>
          release(&wait_lock);
    800023ca:	0022f517          	auipc	a0,0x22f
    800023ce:	ace50513          	addi	a0,a0,-1330 # 80230e98 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	a64080e7          	jalr	-1436(ra) # 80000e36 <release>
          return pid;
    800023da:	a09d                	j	80002440 <waitx+0x120>
            release(&np->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	a58080e7          	jalr	-1448(ra) # 80000e36 <release>
            release(&wait_lock);
    800023e6:	0022f517          	auipc	a0,0x22f
    800023ea:	ab250513          	addi	a0,a0,-1358 # 80230e98 <wait_lock>
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	a48080e7          	jalr	-1464(ra) # 80000e36 <release>
            return -1;
    800023f6:	59fd                	li	s3,-1
    800023f8:	a0a1                	j	80002440 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800023fa:	1a048493          	addi	s1,s1,416
    800023fe:	03348463          	beq	s1,s3,80002426 <waitx+0x106>
      if (np->parent == p)
    80002402:	7c9c                	ld	a5,56(s1)
    80002404:	ff279be3          	bne	a5,s2,800023fa <waitx+0xda>
        acquire(&np->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	978080e7          	jalr	-1672(ra) # 80000d82 <acquire>
        if (np->state == ZOMBIE)
    80002412:	4c9c                	lw	a5,24(s1)
    80002414:	f74785e3          	beq	a5,s4,8000237e <waitx+0x5e>
        release(&np->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	a1c080e7          	jalr	-1508(ra) # 80000e36 <release>
        havekids = 1;
    80002422:	8756                	mv	a4,s5
    80002424:	bfd9                	j	800023fa <waitx+0xda>
    if (!havekids || p->killed)
    80002426:	c701                	beqz	a4,8000242e <waitx+0x10e>
    80002428:	02892783          	lw	a5,40(s2)
    8000242c:	cb8d                	beqz	a5,8000245e <waitx+0x13e>
      release(&wait_lock);
    8000242e:	0022f517          	auipc	a0,0x22f
    80002432:	a6a50513          	addi	a0,a0,-1430 # 80230e98 <wait_lock>
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	a00080e7          	jalr	-1536(ra) # 80000e36 <release>
      return -1;
    8000243e:	59fd                	li	s3,-1
}
    80002440:	854e                	mv	a0,s3
    80002442:	60e6                	ld	ra,88(sp)
    80002444:	6446                	ld	s0,80(sp)
    80002446:	64a6                	ld	s1,72(sp)
    80002448:	6906                	ld	s2,64(sp)
    8000244a:	79e2                	ld	s3,56(sp)
    8000244c:	7a42                	ld	s4,48(sp)
    8000244e:	7aa2                	ld	s5,40(sp)
    80002450:	7b02                	ld	s6,32(sp)
    80002452:	6be2                	ld	s7,24(sp)
    80002454:	6c42                	ld	s8,16(sp)
    80002456:	6ca2                	ld	s9,8(sp)
    80002458:	6d02                	ld	s10,0(sp)
    8000245a:	6125                	addi	sp,sp,96
    8000245c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000245e:	85ea                	mv	a1,s10
    80002460:	854a                	mv	a0,s2
    80002462:	00000097          	auipc	ra,0x0
    80002466:	e5a080e7          	jalr	-422(ra) # 800022bc <sleep>
    havekids = 0;
    8000246a:	b721                	j	80002372 <waitx+0x52>

000000008000246c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000246c:	7139                	addi	sp,sp,-64
    8000246e:	fc06                	sd	ra,56(sp)
    80002470:	f822                	sd	s0,48(sp)
    80002472:	f426                	sd	s1,40(sp)
    80002474:	f04a                	sd	s2,32(sp)
    80002476:	ec4e                	sd	s3,24(sp)
    80002478:	e852                	sd	s4,16(sp)
    8000247a:	e456                	sd	s5,8(sp)
    8000247c:	0080                	addi	s0,sp,64
    8000247e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002480:	0022f497          	auipc	s1,0x22f
    80002484:	e3048493          	addi	s1,s1,-464 # 802312b0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002488:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000248a:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000248c:	00235917          	auipc	s2,0x235
    80002490:	62490913          	addi	s2,s2,1572 # 80237ab0 <tickslock>
    80002494:	a811                	j	800024a8 <wakeup+0x3c>
#endif

#ifdef MLFQ
      p->ticks_elapsed = 0;
#endif
      release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	99e080e7          	jalr	-1634(ra) # 80000e36 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024a0:	1a048493          	addi	s1,s1,416
    800024a4:	03248663          	beq	s1,s2,800024d0 <wakeup+0x64>
    if (p != myproc())
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	6da080e7          	jalr	1754(ra) # 80001b82 <myproc>
    800024b0:	fea488e3          	beq	s1,a0,800024a0 <wakeup+0x34>
      acquire(&p->lock);
    800024b4:	8526                	mv	a0,s1
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	8cc080e7          	jalr	-1844(ra) # 80000d82 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800024be:	4c9c                	lw	a5,24(s1)
    800024c0:	fd379be3          	bne	a5,s3,80002496 <wakeup+0x2a>
    800024c4:	709c                	ld	a5,32(s1)
    800024c6:	fd4798e3          	bne	a5,s4,80002496 <wakeup+0x2a>
        p->state = RUNNABLE;
    800024ca:	0154ac23          	sw	s5,24(s1)
    800024ce:	b7e1                	j	80002496 <wakeup+0x2a>
    }
  }
}
    800024d0:	70e2                	ld	ra,56(sp)
    800024d2:	7442                	ld	s0,48(sp)
    800024d4:	74a2                	ld	s1,40(sp)
    800024d6:	7902                	ld	s2,32(sp)
    800024d8:	69e2                	ld	s3,24(sp)
    800024da:	6a42                	ld	s4,16(sp)
    800024dc:	6aa2                	ld	s5,8(sp)
    800024de:	6121                	addi	sp,sp,64
    800024e0:	8082                	ret

00000000800024e2 <reparent>:
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	e052                	sd	s4,0(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800024f4:	0022f497          	auipc	s1,0x22f
    800024f8:	dbc48493          	addi	s1,s1,-580 # 802312b0 <proc>
      pp->parent = initproc;
    800024fc:	00006a17          	auipc	s4,0x6
    80002500:	70ca0a13          	addi	s4,s4,1804 # 80008c08 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002504:	00235997          	auipc	s3,0x235
    80002508:	5ac98993          	addi	s3,s3,1452 # 80237ab0 <tickslock>
    8000250c:	a029                	j	80002516 <reparent+0x34>
    8000250e:	1a048493          	addi	s1,s1,416
    80002512:	01348d63          	beq	s1,s3,8000252c <reparent+0x4a>
    if (pp->parent == p)
    80002516:	7c9c                	ld	a5,56(s1)
    80002518:	ff279be3          	bne	a5,s2,8000250e <reparent+0x2c>
      pp->parent = initproc;
    8000251c:	000a3503          	ld	a0,0(s4)
    80002520:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002522:	00000097          	auipc	ra,0x0
    80002526:	f4a080e7          	jalr	-182(ra) # 8000246c <wakeup>
    8000252a:	b7d5                	j	8000250e <reparent+0x2c>
}
    8000252c:	70a2                	ld	ra,40(sp)
    8000252e:	7402                	ld	s0,32(sp)
    80002530:	64e2                	ld	s1,24(sp)
    80002532:	6942                	ld	s2,16(sp)
    80002534:	69a2                	ld	s3,8(sp)
    80002536:	6a02                	ld	s4,0(sp)
    80002538:	6145                	addi	sp,sp,48
    8000253a:	8082                	ret

000000008000253c <exit>:
{
    8000253c:	7179                	addi	sp,sp,-48
    8000253e:	f406                	sd	ra,40(sp)
    80002540:	f022                	sd	s0,32(sp)
    80002542:	ec26                	sd	s1,24(sp)
    80002544:	e84a                	sd	s2,16(sp)
    80002546:	e44e                	sd	s3,8(sp)
    80002548:	e052                	sd	s4,0(sp)
    8000254a:	1800                	addi	s0,sp,48
    8000254c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	634080e7          	jalr	1588(ra) # 80001b82 <myproc>
    80002556:	89aa                	mv	s3,a0
  if (p == initproc)
    80002558:	00006797          	auipc	a5,0x6
    8000255c:	6b07b783          	ld	a5,1712(a5) # 80008c08 <initproc>
    80002560:	0d050493          	addi	s1,a0,208
    80002564:	15050913          	addi	s2,a0,336
    80002568:	02a79363          	bne	a5,a0,8000258e <exit+0x52>
    panic("init exiting");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	d1c50513          	addi	a0,a0,-740 # 80008288 <digits+0x248>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	fcc080e7          	jalr	-52(ra) # 80000540 <panic>
      fileclose(f);
    8000257c:	00002097          	auipc	ra,0x2
    80002580:	6d0080e7          	jalr	1744(ra) # 80004c4c <fileclose>
      p->ofile[fd] = 0;
    80002584:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002588:	04a1                	addi	s1,s1,8
    8000258a:	01248563          	beq	s1,s2,80002594 <exit+0x58>
    if (p->ofile[fd])
    8000258e:	6088                	ld	a0,0(s1)
    80002590:	f575                	bnez	a0,8000257c <exit+0x40>
    80002592:	bfdd                	j	80002588 <exit+0x4c>
  begin_op();
    80002594:	00002097          	auipc	ra,0x2
    80002598:	1f0080e7          	jalr	496(ra) # 80004784 <begin_op>
  iput(p->cwd);
    8000259c:	1509b503          	ld	a0,336(s3)
    800025a0:	00002097          	auipc	ra,0x2
    800025a4:	9d2080e7          	jalr	-1582(ra) # 80003f72 <iput>
  end_op();
    800025a8:	00002097          	auipc	ra,0x2
    800025ac:	25a080e7          	jalr	602(ra) # 80004802 <end_op>
  p->cwd = 0;
    800025b0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800025b4:	0022f497          	auipc	s1,0x22f
    800025b8:	8e448493          	addi	s1,s1,-1820 # 80230e98 <wait_lock>
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	7c4080e7          	jalr	1988(ra) # 80000d82 <acquire>
  reparent(p);
    800025c6:	854e                	mv	a0,s3
    800025c8:	00000097          	auipc	ra,0x0
    800025cc:	f1a080e7          	jalr	-230(ra) # 800024e2 <reparent>
  wakeup(p->parent);
    800025d0:	0389b503          	ld	a0,56(s3)
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	e98080e7          	jalr	-360(ra) # 8000246c <wakeup>
  acquire(&p->lock);
    800025dc:	854e                	mv	a0,s3
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	7a4080e7          	jalr	1956(ra) # 80000d82 <acquire>
  p->xstate = status;
    800025e6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025ea:	4795                	li	a5,5
    800025ec:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800025f0:	00006797          	auipc	a5,0x6
    800025f4:	6207a783          	lw	a5,1568(a5) # 80008c10 <ticks>
    800025f8:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	fffff097          	auipc	ra,0xfffff
    80002602:	838080e7          	jalr	-1992(ra) # 80000e36 <release>
  sched();
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	ba4080e7          	jalr	-1116(ra) # 800021aa <sched>
  panic("zombie exit");
    8000260e:	00006517          	auipc	a0,0x6
    80002612:	c8a50513          	addi	a0,a0,-886 # 80008298 <digits+0x258>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	f2a080e7          	jalr	-214(ra) # 80000540 <panic>

000000008000261e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000261e:	7179                	addi	sp,sp,-48
    80002620:	f406                	sd	ra,40(sp)
    80002622:	f022                	sd	s0,32(sp)
    80002624:	ec26                	sd	s1,24(sp)
    80002626:	e84a                	sd	s2,16(sp)
    80002628:	e44e                	sd	s3,8(sp)
    8000262a:	1800                	addi	s0,sp,48
    8000262c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000262e:	0022f497          	auipc	s1,0x22f
    80002632:	c8248493          	addi	s1,s1,-894 # 802312b0 <proc>
    80002636:	00235997          	auipc	s3,0x235
    8000263a:	47a98993          	addi	s3,s3,1146 # 80237ab0 <tickslock>
  {
    acquire(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	742080e7          	jalr	1858(ra) # 80000d82 <acquire>
    if (p->pid == pid)
    80002648:	589c                	lw	a5,48(s1)
    8000264a:	01278d63          	beq	a5,s2,80002664 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	7e6080e7          	jalr	2022(ra) # 80000e36 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002658:	1a048493          	addi	s1,s1,416
    8000265c:	ff3491e3          	bne	s1,s3,8000263e <kill+0x20>
  }
  return -1;
    80002660:	557d                	li	a0,-1
    80002662:	a829                	j	8000267c <kill+0x5e>
      p->killed = 1;
    80002664:	4785                	li	a5,1
    80002666:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002668:	4c98                	lw	a4,24(s1)
    8000266a:	4789                	li	a5,2
    8000266c:	00f70f63          	beq	a4,a5,8000268a <kill+0x6c>
      release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	7c4080e7          	jalr	1988(ra) # 80000e36 <release>
      return 0;
    8000267a:	4501                	li	a0,0
}
    8000267c:	70a2                	ld	ra,40(sp)
    8000267e:	7402                	ld	s0,32(sp)
    80002680:	64e2                	ld	s1,24(sp)
    80002682:	6942                	ld	s2,16(sp)
    80002684:	69a2                	ld	s3,8(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret
        p->state = RUNNABLE;
    8000268a:	478d                	li	a5,3
    8000268c:	cc9c                	sw	a5,24(s1)
    8000268e:	b7cd                	j	80002670 <kill+0x52>

0000000080002690 <setkilled>:

void setkilled(struct proc *p)
{
    80002690:	1101                	addi	sp,sp,-32
    80002692:	ec06                	sd	ra,24(sp)
    80002694:	e822                	sd	s0,16(sp)
    80002696:	e426                	sd	s1,8(sp)
    80002698:	1000                	addi	s0,sp,32
    8000269a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	6e6080e7          	jalr	1766(ra) # 80000d82 <acquire>
  p->killed = 1;
    800026a4:	4785                	li	a5,1
    800026a6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	78c080e7          	jalr	1932(ra) # 80000e36 <release>
}
    800026b2:	60e2                	ld	ra,24(sp)
    800026b4:	6442                	ld	s0,16(sp)
    800026b6:	64a2                	ld	s1,8(sp)
    800026b8:	6105                	addi	sp,sp,32
    800026ba:	8082                	ret

00000000800026bc <killed>:

int killed(struct proc *p)
{
    800026bc:	1101                	addi	sp,sp,-32
    800026be:	ec06                	sd	ra,24(sp)
    800026c0:	e822                	sd	s0,16(sp)
    800026c2:	e426                	sd	s1,8(sp)
    800026c4:	e04a                	sd	s2,0(sp)
    800026c6:	1000                	addi	s0,sp,32
    800026c8:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	6b8080e7          	jalr	1720(ra) # 80000d82 <acquire>
  k = p->killed;
    800026d2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	75e080e7          	jalr	1886(ra) # 80000e36 <release>
  return k;
}
    800026e0:	854a                	mv	a0,s2
    800026e2:	60e2                	ld	ra,24(sp)
    800026e4:	6442                	ld	s0,16(sp)
    800026e6:	64a2                	ld	s1,8(sp)
    800026e8:	6902                	ld	s2,0(sp)
    800026ea:	6105                	addi	sp,sp,32
    800026ec:	8082                	ret

00000000800026ee <wait>:
{
    800026ee:	715d                	addi	sp,sp,-80
    800026f0:	e486                	sd	ra,72(sp)
    800026f2:	e0a2                	sd	s0,64(sp)
    800026f4:	fc26                	sd	s1,56(sp)
    800026f6:	f84a                	sd	s2,48(sp)
    800026f8:	f44e                	sd	s3,40(sp)
    800026fa:	f052                	sd	s4,32(sp)
    800026fc:	ec56                	sd	s5,24(sp)
    800026fe:	e85a                	sd	s6,16(sp)
    80002700:	e45e                	sd	s7,8(sp)
    80002702:	e062                	sd	s8,0(sp)
    80002704:	0880                	addi	s0,sp,80
    80002706:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	47a080e7          	jalr	1146(ra) # 80001b82 <myproc>
    80002710:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002712:	0022e517          	auipc	a0,0x22e
    80002716:	78650513          	addi	a0,a0,1926 # 80230e98 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	668080e7          	jalr	1640(ra) # 80000d82 <acquire>
    havekids = 0;
    80002722:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002724:	4a15                	li	s4,5
        havekids = 1;
    80002726:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002728:	00235997          	auipc	s3,0x235
    8000272c:	38898993          	addi	s3,s3,904 # 80237ab0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002730:	0022ec17          	auipc	s8,0x22e
    80002734:	768c0c13          	addi	s8,s8,1896 # 80230e98 <wait_lock>
    havekids = 0;
    80002738:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000273a:	0022f497          	auipc	s1,0x22f
    8000273e:	b7648493          	addi	s1,s1,-1162 # 802312b0 <proc>
    80002742:	a0bd                	j	800027b0 <wait+0xc2>
          pid = pp->pid;
    80002744:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002748:	000b0e63          	beqz	s6,80002764 <wait+0x76>
    8000274c:	4691                	li	a3,4
    8000274e:	02c48613          	addi	a2,s1,44
    80002752:	85da                	mv	a1,s6
    80002754:	05093503          	ld	a0,80(s2)
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	0b6080e7          	jalr	182(ra) # 8000180e <copyout>
    80002760:	02054563          	bltz	a0,8000278a <wait+0x9c>
          freeproc(pp);
    80002764:	8526                	mv	a0,s1
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	5ce080e7          	jalr	1486(ra) # 80001d34 <freeproc>
          release(&pp->lock);
    8000276e:	8526                	mv	a0,s1
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	6c6080e7          	jalr	1734(ra) # 80000e36 <release>
          release(&wait_lock);
    80002778:	0022e517          	auipc	a0,0x22e
    8000277c:	72050513          	addi	a0,a0,1824 # 80230e98 <wait_lock>
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	6b6080e7          	jalr	1718(ra) # 80000e36 <release>
          return pid;
    80002788:	a0b5                	j	800027f4 <wait+0x106>
            release(&pp->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	6aa080e7          	jalr	1706(ra) # 80000e36 <release>
            release(&wait_lock);
    80002794:	0022e517          	auipc	a0,0x22e
    80002798:	70450513          	addi	a0,a0,1796 # 80230e98 <wait_lock>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	69a080e7          	jalr	1690(ra) # 80000e36 <release>
            return -1;
    800027a4:	59fd                	li	s3,-1
    800027a6:	a0b9                	j	800027f4 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800027a8:	1a048493          	addi	s1,s1,416
    800027ac:	03348463          	beq	s1,s3,800027d4 <wait+0xe6>
      if (pp->parent == p)
    800027b0:	7c9c                	ld	a5,56(s1)
    800027b2:	ff279be3          	bne	a5,s2,800027a8 <wait+0xba>
        acquire(&pp->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	5ca080e7          	jalr	1482(ra) # 80000d82 <acquire>
        if (pp->state == ZOMBIE)
    800027c0:	4c9c                	lw	a5,24(s1)
    800027c2:	f94781e3          	beq	a5,s4,80002744 <wait+0x56>
        release(&pp->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	66e080e7          	jalr	1646(ra) # 80000e36 <release>
        havekids = 1;
    800027d0:	8756                	mv	a4,s5
    800027d2:	bfd9                	j	800027a8 <wait+0xba>
    if (!havekids || killed(p))
    800027d4:	c719                	beqz	a4,800027e2 <wait+0xf4>
    800027d6:	854a                	mv	a0,s2
    800027d8:	00000097          	auipc	ra,0x0
    800027dc:	ee4080e7          	jalr	-284(ra) # 800026bc <killed>
    800027e0:	c51d                	beqz	a0,8000280e <wait+0x120>
      release(&wait_lock);
    800027e2:	0022e517          	auipc	a0,0x22e
    800027e6:	6b650513          	addi	a0,a0,1718 # 80230e98 <wait_lock>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	64c080e7          	jalr	1612(ra) # 80000e36 <release>
      return -1;
    800027f2:	59fd                	li	s3,-1
}
    800027f4:	854e                	mv	a0,s3
    800027f6:	60a6                	ld	ra,72(sp)
    800027f8:	6406                	ld	s0,64(sp)
    800027fa:	74e2                	ld	s1,56(sp)
    800027fc:	7942                	ld	s2,48(sp)
    800027fe:	79a2                	ld	s3,40(sp)
    80002800:	7a02                	ld	s4,32(sp)
    80002802:	6ae2                	ld	s5,24(sp)
    80002804:	6b42                	ld	s6,16(sp)
    80002806:	6ba2                	ld	s7,8(sp)
    80002808:	6c02                	ld	s8,0(sp)
    8000280a:	6161                	addi	sp,sp,80
    8000280c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000280e:	85e2                	mv	a1,s8
    80002810:	854a                	mv	a0,s2
    80002812:	00000097          	auipc	ra,0x0
    80002816:	aaa080e7          	jalr	-1366(ra) # 800022bc <sleep>
    havekids = 0;
    8000281a:	bf39                	j	80002738 <wait+0x4a>

000000008000281c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	addi	s0,sp,48
    8000282c:	84aa                	mv	s1,a0
    8000282e:	892e                	mv	s2,a1
    80002830:	89b2                	mv	s3,a2
    80002832:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002834:	fffff097          	auipc	ra,0xfffff
    80002838:	34e080e7          	jalr	846(ra) # 80001b82 <myproc>
  if (user_dst)
    8000283c:	c08d                	beqz	s1,8000285e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000283e:	86d2                	mv	a3,s4
    80002840:	864e                	mv	a2,s3
    80002842:	85ca                	mv	a1,s2
    80002844:	6928                	ld	a0,80(a0)
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	fc8080e7          	jalr	-56(ra) # 8000180e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000284e:	70a2                	ld	ra,40(sp)
    80002850:	7402                	ld	s0,32(sp)
    80002852:	64e2                	ld	s1,24(sp)
    80002854:	6942                	ld	s2,16(sp)
    80002856:	69a2                	ld	s3,8(sp)
    80002858:	6a02                	ld	s4,0(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret
    memmove((char *)dst, src, len);
    8000285e:	000a061b          	sext.w	a2,s4
    80002862:	85ce                	mv	a1,s3
    80002864:	854a                	mv	a0,s2
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	674080e7          	jalr	1652(ra) # 80000eda <memmove>
    return 0;
    8000286e:	8526                	mv	a0,s1
    80002870:	bff9                	j	8000284e <either_copyout+0x32>

0000000080002872 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002872:	7179                	addi	sp,sp,-48
    80002874:	f406                	sd	ra,40(sp)
    80002876:	f022                	sd	s0,32(sp)
    80002878:	ec26                	sd	s1,24(sp)
    8000287a:	e84a                	sd	s2,16(sp)
    8000287c:	e44e                	sd	s3,8(sp)
    8000287e:	e052                	sd	s4,0(sp)
    80002880:	1800                	addi	s0,sp,48
    80002882:	892a                	mv	s2,a0
    80002884:	84ae                	mv	s1,a1
    80002886:	89b2                	mv	s3,a2
    80002888:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	2f8080e7          	jalr	760(ra) # 80001b82 <myproc>
  if (user_src)
    80002892:	c08d                	beqz	s1,800028b4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002894:	86d2                	mv	a3,s4
    80002896:	864e                	mv	a2,s3
    80002898:	85ca                	mv	a1,s2
    8000289a:	6928                	ld	a0,80(a0)
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	032080e7          	jalr	50(ra) # 800018ce <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800028a4:	70a2                	ld	ra,40(sp)
    800028a6:	7402                	ld	s0,32(sp)
    800028a8:	64e2                	ld	s1,24(sp)
    800028aa:	6942                	ld	s2,16(sp)
    800028ac:	69a2                	ld	s3,8(sp)
    800028ae:	6a02                	ld	s4,0(sp)
    800028b0:	6145                	addi	sp,sp,48
    800028b2:	8082                	ret
    memmove(dst, (char *)src, len);
    800028b4:	000a061b          	sext.w	a2,s4
    800028b8:	85ce                	mv	a1,s3
    800028ba:	854a                	mv	a0,s2
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	61e080e7          	jalr	1566(ra) # 80000eda <memmove>
    return 0;
    800028c4:	8526                	mv	a0,s1
    800028c6:	bff9                	j	800028a4 <either_copyin+0x32>

00000000800028c8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028c8:	715d                	addi	sp,sp,-80
    800028ca:	e486                	sd	ra,72(sp)
    800028cc:	e0a2                	sd	s0,64(sp)
    800028ce:	fc26                	sd	s1,56(sp)
    800028d0:	f84a                	sd	s2,48(sp)
    800028d2:	f44e                	sd	s3,40(sp)
    800028d4:	f052                	sd	s4,32(sp)
    800028d6:	ec56                	sd	s5,24(sp)
    800028d8:	e85a                	sd	s6,16(sp)
    800028da:	e45e                	sd	s7,8(sp)
    800028dc:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800028de:	00006517          	auipc	a0,0x6
    800028e2:	81250513          	addi	a0,a0,-2030 # 800080f0 <digits+0xb0>
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	ca4080e7          	jalr	-860(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028ee:	0022f497          	auipc	s1,0x22f
    800028f2:	b1a48493          	addi	s1,s1,-1254 # 80231408 <proc+0x158>
    800028f6:	00235917          	auipc	s2,0x235
    800028fa:	31290913          	addi	s2,s2,786 # 80237c08 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fe:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002900:	00006997          	auipc	s3,0x6
    80002904:	9a898993          	addi	s3,s3,-1624 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002908:	00006a97          	auipc	s5,0x6
    8000290c:	9a8a8a93          	addi	s5,s5,-1624 # 800082b0 <digits+0x270>
    printf("\n");
    80002910:	00005a17          	auipc	s4,0x5
    80002914:	7e0a0a13          	addi	s4,s4,2016 # 800080f0 <digits+0xb0>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002918:	00006b97          	auipc	s7,0x6
    8000291c:	9d8b8b93          	addi	s7,s7,-1576 # 800082f0 <states.0>
    80002920:	a00d                	j	80002942 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002922:	ed86a583          	lw	a1,-296(a3)
    80002926:	8556                	mv	a0,s5
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c62080e7          	jalr	-926(ra) # 8000058a <printf>
    printf("\n");
    80002930:	8552                	mv	a0,s4
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c58080e7          	jalr	-936(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000293a:	1a048493          	addi	s1,s1,416
    8000293e:	03248263          	beq	s1,s2,80002962 <procdump+0x9a>
    if (p->state == UNUSED)
    80002942:	86a6                	mv	a3,s1
    80002944:	ec04a783          	lw	a5,-320(s1)
    80002948:	dbed                	beqz	a5,8000293a <procdump+0x72>
      state = "???";
    8000294a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000294c:	fcfb6be3          	bltu	s6,a5,80002922 <procdump+0x5a>
    80002950:	02079713          	slli	a4,a5,0x20
    80002954:	01d75793          	srli	a5,a4,0x1d
    80002958:	97de                	add	a5,a5,s7
    8000295a:	6390                	ld	a2,0(a5)
    8000295c:	f279                	bnez	a2,80002922 <procdump+0x5a>
      state = "???";
    8000295e:	864e                	mv	a2,s3
    80002960:	b7c9                	j	80002922 <procdump+0x5a>
  }
}
    80002962:	60a6                	ld	ra,72(sp)
    80002964:	6406                	ld	s0,64(sp)
    80002966:	74e2                	ld	s1,56(sp)
    80002968:	7942                	ld	s2,48(sp)
    8000296a:	79a2                	ld	s3,40(sp)
    8000296c:	7a02                	ld	s4,32(sp)
    8000296e:	6ae2                	ld	s5,24(sp)
    80002970:	6b42                	ld	s6,16(sp)
    80002972:	6ba2                	ld	s7,8(sp)
    80002974:	6161                	addi	sp,sp,80
    80002976:	8082                	ret

0000000080002978 <setpriority>:

int setpriority(int new_priority, int pid)
{
    80002978:	1141                	addi	sp,sp,-16
    8000297a:	e422                	sd	s0,8(sp)
    8000297c:	0800                	addi	s0,sp,16
  if (new_priority < old_priority)
    yield();
  return old_priority;
#endif
  return -2;
}
    8000297e:	5579                	li	a0,-2
    80002980:	6422                	ld	s0,8(sp)
    80002982:	0141                	addi	sp,sp,16
    80002984:	8082                	ret

0000000080002986 <set_tickets>:

int set_tickets(int no_of_tickets)
{
    80002986:	1141                	addi	sp,sp,-16
    80002988:	e422                	sd	s0,8(sp)
    8000298a:	0800                	addi	s0,sp,16

  p->tickets = no_of_tickets;

#endif
  return 1;
}
    8000298c:	4505                	li	a0,1
    8000298e:	6422                	ld	s0,8(sp)
    80002990:	0141                	addi	sp,sp,16
    80002992:	8082                	ret

0000000080002994 <swtch>:
    80002994:	00153023          	sd	ra,0(a0)
    80002998:	00253423          	sd	sp,8(a0)
    8000299c:	e900                	sd	s0,16(a0)
    8000299e:	ed04                	sd	s1,24(a0)
    800029a0:	03253023          	sd	s2,32(a0)
    800029a4:	03353423          	sd	s3,40(a0)
    800029a8:	03453823          	sd	s4,48(a0)
    800029ac:	03553c23          	sd	s5,56(a0)
    800029b0:	05653023          	sd	s6,64(a0)
    800029b4:	05753423          	sd	s7,72(a0)
    800029b8:	05853823          	sd	s8,80(a0)
    800029bc:	05953c23          	sd	s9,88(a0)
    800029c0:	07a53023          	sd	s10,96(a0)
    800029c4:	07b53423          	sd	s11,104(a0)
    800029c8:	0005b083          	ld	ra,0(a1)
    800029cc:	0085b103          	ld	sp,8(a1)
    800029d0:	6980                	ld	s0,16(a1)
    800029d2:	6d84                	ld	s1,24(a1)
    800029d4:	0205b903          	ld	s2,32(a1)
    800029d8:	0285b983          	ld	s3,40(a1)
    800029dc:	0305ba03          	ld	s4,48(a1)
    800029e0:	0385ba83          	ld	s5,56(a1)
    800029e4:	0405bb03          	ld	s6,64(a1)
    800029e8:	0485bb83          	ld	s7,72(a1)
    800029ec:	0505bc03          	ld	s8,80(a1)
    800029f0:	0585bc83          	ld	s9,88(a1)
    800029f4:	0605bd03          	ld	s10,96(a1)
    800029f8:	0685bd83          	ld	s11,104(a1)
    800029fc:	8082                	ret

00000000800029fe <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800029fe:	1141                	addi	sp,sp,-16
    80002a00:	e406                	sd	ra,8(sp)
    80002a02:	e022                	sd	s0,0(sp)
    80002a04:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a06:	00006597          	auipc	a1,0x6
    80002a0a:	91a58593          	addi	a1,a1,-1766 # 80008320 <states.0+0x30>
    80002a0e:	00235517          	auipc	a0,0x235
    80002a12:	0a250513          	addi	a0,a0,162 # 80237ab0 <tickslock>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	2dc080e7          	jalr	732(ra) # 80000cf2 <initlock>
}
    80002a1e:	60a2                	ld	ra,8(sp)
    80002a20:	6402                	ld	s0,0(sp)
    80002a22:	0141                	addi	sp,sp,16
    80002a24:	8082                	ret

0000000080002a26 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002a26:	1141                	addi	sp,sp,-16
    80002a28:	e422                	sd	s0,8(sp)
    80002a2a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a2c:	00004797          	auipc	a5,0x4
    80002a30:	87478793          	addi	a5,a5,-1932 # 800062a0 <kernelvec>
    80002a34:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a38:	6422                	ld	s0,8(sp)
    80002a3a:	0141                	addi	sp,sp,16
    80002a3c:	8082                	ret

0000000080002a3e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002a3e:	1141                	addi	sp,sp,-16
    80002a40:	e406                	sd	ra,8(sp)
    80002a42:	e022                	sd	s0,0(sp)
    80002a44:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	13c080e7          	jalr	316(ra) # 80001b82 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a52:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a54:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a58:	00004697          	auipc	a3,0x4
    80002a5c:	5a868693          	addi	a3,a3,1448 # 80007000 <_trampoline>
    80002a60:	00004717          	auipc	a4,0x4
    80002a64:	5a070713          	addi	a4,a4,1440 # 80007000 <_trampoline>
    80002a68:	8f15                	sub	a4,a4,a3
    80002a6a:	040007b7          	lui	a5,0x4000
    80002a6e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a70:	07b2                	slli	a5,a5,0xc
    80002a72:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a74:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a78:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a7a:	18002673          	csrr	a2,satp
    80002a7e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a80:	6d30                	ld	a2,88(a0)
    80002a82:	6138                	ld	a4,64(a0)
    80002a84:	6585                	lui	a1,0x1
    80002a86:	972e                	add	a4,a4,a1
    80002a88:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a8a:	6d38                	ld	a4,88(a0)
    80002a8c:	00000617          	auipc	a2,0x0
    80002a90:	2a260613          	addi	a2,a2,674 # 80002d2e <usertrap>
    80002a94:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a96:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a98:	8612                	mv	a2,tp
    80002a9a:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9c:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002aa0:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002aa4:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002aac:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aae:	6f18                	ld	a4,24(a4)
    80002ab0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ab4:	6928                	ld	a0,80(a0)
    80002ab6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ab8:	00004717          	auipc	a4,0x4
    80002abc:	5e470713          	addi	a4,a4,1508 # 8000709c <userret>
    80002ac0:	8f15                	sub	a4,a4,a3
    80002ac2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ac4:	577d                	li	a4,-1
    80002ac6:	177e                	slli	a4,a4,0x3f
    80002ac8:	8d59                	or	a0,a0,a4
    80002aca:	9782                	jalr	a5
}
    80002acc:	60a2                	ld	ra,8(sp)
    80002ace:	6402                	ld	s0,0(sp)
    80002ad0:	0141                	addi	sp,sp,16
    80002ad2:	8082                	ret

0000000080002ad4 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002ad4:	1101                	addi	sp,sp,-32
    80002ad6:	ec06                	sd	ra,24(sp)
    80002ad8:	e822                	sd	s0,16(sp)
    80002ada:	e426                	sd	s1,8(sp)
    80002adc:	e04a                	sd	s2,0(sp)
    80002ade:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ae0:	00235917          	auipc	s2,0x235
    80002ae4:	fd090913          	addi	s2,s2,-48 # 80237ab0 <tickslock>
    80002ae8:	854a                	mv	a0,s2
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	298080e7          	jalr	664(ra) # 80000d82 <acquire>
  ticks++;
    80002af2:	00006497          	auipc	s1,0x6
    80002af6:	11e48493          	addi	s1,s1,286 # 80008c10 <ticks>
    80002afa:	409c                	lw	a5,0(s1)
    80002afc:	2785                	addiw	a5,a5,1
    80002afe:	c09c                	sw	a5,0(s1)
  update_time();
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	5ac080e7          	jalr	1452(ra) # 800020ac <update_time>
  wakeup(&ticks);
    80002b08:	8526                	mv	a0,s1
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	962080e7          	jalr	-1694(ra) # 8000246c <wakeup>
  release(&tickslock);
    80002b12:	854a                	mv	a0,s2
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	322080e7          	jalr	802(ra) # 80000e36 <release>
}
    80002b1c:	60e2                	ld	ra,24(sp)
    80002b1e:	6442                	ld	s0,16(sp)
    80002b20:	64a2                	ld	s1,8(sp)
    80002b22:	6902                	ld	s2,0(sp)
    80002b24:	6105                	addi	sp,sp,32
    80002b26:	8082                	ret

0000000080002b28 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b32:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b36:	00074d63          	bltz	a4,80002b50 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b3a:	57fd                	li	a5,-1
    80002b3c:	17fe                	slli	a5,a5,0x3f
    80002b3e:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002b40:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b42:	06f70363          	beq	a4,a5,80002ba8 <devintr+0x80>
  }
}
    80002b46:	60e2                	ld	ra,24(sp)
    80002b48:	6442                	ld	s0,16(sp)
    80002b4a:	64a2                	ld	s1,8(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret
      (scause & 0xff) == 9)
    80002b50:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002b54:	46a5                	li	a3,9
    80002b56:	fed792e3          	bne	a5,a3,80002b3a <devintr+0x12>
    int irq = plic_claim();
    80002b5a:	00004097          	auipc	ra,0x4
    80002b5e:	84e080e7          	jalr	-1970(ra) # 800063a8 <plic_claim>
    80002b62:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002b64:	47a9                	li	a5,10
    80002b66:	02f50763          	beq	a0,a5,80002b94 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002b6a:	4785                	li	a5,1
    80002b6c:	02f50963          	beq	a0,a5,80002b9e <devintr+0x76>
    return 1;
    80002b70:	4505                	li	a0,1
    else if (irq)
    80002b72:	d8f1                	beqz	s1,80002b46 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b74:	85a6                	mv	a1,s1
    80002b76:	00005517          	auipc	a0,0x5
    80002b7a:	7b250513          	addi	a0,a0,1970 # 80008328 <states.0+0x38>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a0c080e7          	jalr	-1524(ra) # 8000058a <printf>
      plic_complete(irq);
    80002b86:	8526                	mv	a0,s1
    80002b88:	00004097          	auipc	ra,0x4
    80002b8c:	844080e7          	jalr	-1980(ra) # 800063cc <plic_complete>
    return 1;
    80002b90:	4505                	li	a0,1
    80002b92:	bf55                	j	80002b46 <devintr+0x1e>
      uartintr();
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	e04080e7          	jalr	-508(ra) # 80000998 <uartintr>
    80002b9c:	b7ed                	j	80002b86 <devintr+0x5e>
      virtio_disk_intr();
    80002b9e:	00004097          	auipc	ra,0x4
    80002ba2:	cf6080e7          	jalr	-778(ra) # 80006894 <virtio_disk_intr>
    80002ba6:	b7c5                	j	80002b86 <devintr+0x5e>
    if (cpuid() == 0)
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	fae080e7          	jalr	-82(ra) # 80001b56 <cpuid>
    80002bb0:	c901                	beqz	a0,80002bc0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bb2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bb6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bb8:	14479073          	csrw	sip,a5
    return 2;
    80002bbc:	4509                	li	a0,2
    80002bbe:	b761                	j	80002b46 <devintr+0x1e>
      clockintr();
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	f14080e7          	jalr	-236(ra) # 80002ad4 <clockintr>
    80002bc8:	b7ed                	j	80002bb2 <devintr+0x8a>

0000000080002bca <kerneltrap>:
{
    80002bca:	7179                	addi	sp,sp,-48
    80002bcc:	f406                	sd	ra,40(sp)
    80002bce:	f022                	sd	s0,32(sp)
    80002bd0:	ec26                	sd	s1,24(sp)
    80002bd2:	e84a                	sd	s2,16(sp)
    80002bd4:	e44e                	sd	s3,8(sp)
    80002bd6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002be4:	1004f793          	andi	a5,s1,256
    80002be8:	cb85                	beqz	a5,80002c18 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bee:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002bf0:	ef85                	bnez	a5,80002c28 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	f36080e7          	jalr	-202(ra) # 80002b28 <devintr>
    80002bfa:	cd1d                	beqz	a0,80002c38 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bfc:	4789                	li	a5,2
    80002bfe:	06f50a63          	beq	a0,a5,80002c72 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c02:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c06:	10049073          	csrw	sstatus,s1
}
    80002c0a:	70a2                	ld	ra,40(sp)
    80002c0c:	7402                	ld	s0,32(sp)
    80002c0e:	64e2                	ld	s1,24(sp)
    80002c10:	6942                	ld	s2,16(sp)
    80002c12:	69a2                	ld	s3,8(sp)
    80002c14:	6145                	addi	sp,sp,48
    80002c16:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c18:	00005517          	auipc	a0,0x5
    80002c1c:	73050513          	addi	a0,a0,1840 # 80008348 <states.0+0x58>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	920080e7          	jalr	-1760(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c28:	00005517          	auipc	a0,0x5
    80002c2c:	74850513          	addi	a0,a0,1864 # 80008370 <states.0+0x80>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	910080e7          	jalr	-1776(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002c38:	85ce                	mv	a1,s3
    80002c3a:	00005517          	auipc	a0,0x5
    80002c3e:	75650513          	addi	a0,a0,1878 # 80008390 <states.0+0xa0>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	948080e7          	jalr	-1720(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c4e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	74e50513          	addi	a0,a0,1870 # 800083a0 <states.0+0xb0>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	930080e7          	jalr	-1744(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	75650513          	addi	a0,a0,1878 # 800083b8 <states.0+0xc8>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	8d6080e7          	jalr	-1834(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	f10080e7          	jalr	-240(ra) # 80001b82 <myproc>
    80002c7a:	d541                	beqz	a0,80002c02 <kerneltrap+0x38>
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	f06080e7          	jalr	-250(ra) # 80001b82 <myproc>
    80002c84:	4d18                	lw	a4,24(a0)
    80002c86:	4791                	li	a5,4
    80002c88:	f6f71de3          	bne	a4,a5,80002c02 <kerneltrap+0x38>
    yield();
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	5f4080e7          	jalr	1524(ra) # 80002280 <yield>
    80002c94:	b7bd                	j	80002c02 <kerneltrap+0x38>

0000000080002c96 <cow_fault>:
  //   return -1;

  if (va >= MAXVA)
    return -1;

  if (va == 0)
    80002c96:	fff58713          	addi	a4,a1,-1 # fff <_entry-0x7ffff001>
    80002c9a:	f80007b7          	lui	a5,0xf8000
    80002c9e:	83e9                	srli	a5,a5,0x1a
    80002ca0:	06e7ef63          	bltu	a5,a4,80002d1e <cow_fault+0x88>
{
    80002ca4:	7179                	addi	sp,sp,-48
    80002ca6:	f406                	sd	ra,40(sp)
    80002ca8:	f022                	sd	s0,32(sp)
    80002caa:	ec26                	sd	s1,24(sp)
    80002cac:	e84a                	sd	s2,16(sp)
    80002cae:	e44e                	sd	s3,8(sp)
    80002cb0:	1800                	addi	s0,sp,48
    return -1;

  pte_t *pte = walk(pagetable, va, 0);
    80002cb2:	4601                	li	a2,0
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	4ae080e7          	jalr	1198(ra) # 80001162 <walk>
    80002cbc:	84aa                	mv	s1,a0
  if (pte == 0)
    80002cbe:	c135                	beqz	a0,80002d22 <cow_fault+0x8c>
    return -1;

  if ((*pte & PTE_U) == 0 || (*pte & PTE_V) == 0)
    80002cc0:	00053903          	ld	s2,0(a0)
    80002cc4:	01197713          	andi	a4,s2,17
    80002cc8:	47c5                	li	a5,17
    80002cca:	04f71e63          	bne	a4,a5,80002d26 <cow_fault+0x90>

  uint64 pa = PTE2PA(*pte);
  // if (pa == 0)
  //   return -1;

  if (*pte & PTE_COW)
    80002cce:	10097793          	andi	a5,s2,256

    decrease_paref(pa);
    return 0;
  }

  return 0;
    80002cd2:	4501                	li	a0,0
  if (*pte & PTE_COW)
    80002cd4:	eb81                	bnez	a5,80002ce4 <cow_fault+0x4e>
    80002cd6:	70a2                	ld	ra,40(sp)
    80002cd8:	7402                	ld	s0,32(sp)
    80002cda:	64e2                	ld	s1,24(sp)
    80002cdc:	6942                	ld	s2,16(sp)
    80002cde:	69a2                	ld	s3,8(sp)
    80002ce0:	6145                	addi	sp,sp,48
    80002ce2:	8082                	ret
    uint64 newpa = (uint64)kalloc();
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	f70080e7          	jalr	-144(ra) # 80000c54 <kalloc>
    80002cec:	89aa                	mv	s3,a0
    if (newpa == 0)
    80002cee:	cd15                	beqz	a0,80002d2a <cow_fault+0x94>
  uint64 pa = PTE2PA(*pte);
    80002cf0:	00a95913          	srli	s2,s2,0xa
    80002cf4:	0932                	slli	s2,s2,0xc
    memmove((void *)newpa, (void *)pa, PGSIZE);
    80002cf6:	6605                	lui	a2,0x1
    80002cf8:	85ca                	mv	a1,s2
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	1e0080e7          	jalr	480(ra) # 80000eda <memmove>
    *pte = PA2PTE(newpa) | PTE_U | PTE_V | PTE_W | PTE_X | PTE_R;
    80002d02:	00c9d993          	srli	s3,s3,0xc
    80002d06:	09aa                	slli	s3,s3,0xa
    80002d08:	01f9e993          	ori	s3,s3,31
    80002d0c:	0134b023          	sd	s3,0(s1)
    decrease_paref(pa);
    80002d10:	854a                	mv	a0,s2
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	d3c080e7          	jalr	-708(ra) # 80000a4e <decrease_paref>
    return 0;
    80002d1a:	4501                	li	a0,0
    80002d1c:	bf6d                	j	80002cd6 <cow_fault+0x40>
    return -1;
    80002d1e:	557d                	li	a0,-1
    80002d20:	8082                	ret
    return -1;
    80002d22:	557d                	li	a0,-1
    80002d24:	bf4d                	j	80002cd6 <cow_fault+0x40>
    return -1;
    80002d26:	557d                	li	a0,-1
    80002d28:	b77d                	j	80002cd6 <cow_fault+0x40>
      return -1;
    80002d2a:	557d                	li	a0,-1
    80002d2c:	b76d                	j	80002cd6 <cow_fault+0x40>

0000000080002d2e <usertrap>:
{
    80002d2e:	1101                	addi	sp,sp,-32
    80002d30:	ec06                	sd	ra,24(sp)
    80002d32:	e822                	sd	s0,16(sp)
    80002d34:	e426                	sd	s1,8(sp)
    80002d36:	e04a                	sd	s2,0(sp)
    80002d38:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3a:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d3e:	1007f793          	andi	a5,a5,256
    80002d42:	e7a5                	bnez	a5,80002daa <usertrap+0x7c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d44:	00003797          	auipc	a5,0x3
    80002d48:	55c78793          	addi	a5,a5,1372 # 800062a0 <kernelvec>
    80002d4c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	e32080e7          	jalr	-462(ra) # 80001b82 <myproc>
    80002d58:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d5a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d5c:	14102773          	csrr	a4,sepc
    80002d60:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d62:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d66:	47a1                	li	a5,8
    80002d68:	04f70963          	beq	a4,a5,80002dba <usertrap+0x8c>
    80002d6c:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002d70:	47bd                	li	a5,15
    80002d72:	06f70f63          	beq	a4,a5,80002df0 <usertrap+0xc2>
  else if ((which_dev = devintr()) != 0)
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	db2080e7          	jalr	-590(ra) # 80002b28 <devintr>
    80002d7e:	892a                	mv	s2,a0
    80002d80:	cd65                	beqz	a0,80002e78 <usertrap+0x14a>
    if (which_dev == 2 && p->alarmset == 0 && p->alarm_called == 1)
    80002d82:	4789                	li	a5,2
    80002d84:	08f50663          	beq	a0,a5,80002e10 <usertrap+0xe2>
  if (killed(p))
    80002d88:	8526                	mv	a0,s1
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	932080e7          	jalr	-1742(ra) # 800026bc <killed>
    80002d92:	12051063          	bnez	a0,80002eb2 <usertrap+0x184>
  usertrapret();
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	ca8080e7          	jalr	-856(ra) # 80002a3e <usertrapret>
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6902                	ld	s2,0(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret
    panic("usertrap: not from user mode");
    80002daa:	00005517          	auipc	a0,0x5
    80002dae:	61e50513          	addi	a0,a0,1566 # 800083c8 <states.0+0xd8>
    80002db2:	ffffd097          	auipc	ra,0xffffd
    80002db6:	78e080e7          	jalr	1934(ra) # 80000540 <panic>
    if (killed(p))
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	902080e7          	jalr	-1790(ra) # 800026bc <killed>
    80002dc2:	e10d                	bnez	a0,80002de4 <usertrap+0xb6>
    p->trapframe->epc += 4;
    80002dc4:	6cb8                	ld	a4,88(s1)
    80002dc6:	6f1c                	ld	a5,24(a4)
    80002dc8:	0791                	addi	a5,a5,4
    80002dca:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dcc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dd0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dd4:	10079073          	csrw	sstatus,a5
    syscall();
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	272080e7          	jalr	626(ra) # 8000304a <syscall>
  int which_dev = 0;
    80002de0:	4901                	li	s2,0
    80002de2:	b75d                	j	80002d88 <usertrap+0x5a>
      exit(-1);
    80002de4:	557d                	li	a0,-1
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	756080e7          	jalr	1878(ra) # 8000253c <exit>
    80002dee:	bfd9                	j	80002dc4 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002df0:	143025f3          	csrr	a1,stval
    if (cow_fault(p->pagetable, r_stval()) < 0)
    80002df4:	6928                	ld	a0,80(a0)
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	ea0080e7          	jalr	-352(ra) # 80002c96 <cow_fault>
  int which_dev = 0;
    80002dfe:	4901                	li	s2,0
    if (cow_fault(p->pagetable, r_stval()) < 0)
    80002e00:	f80554e3          	bgez	a0,80002d88 <usertrap+0x5a>
      setkilled(p);
    80002e04:	8526                	mv	a0,s1
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	88a080e7          	jalr	-1910(ra) # 80002690 <setkilled>
    80002e0e:	bfad                	j	80002d88 <usertrap+0x5a>
    if (which_dev == 2 && p->alarmset == 0 && p->alarm_called == 1)
    80002e10:	1804a783          	lw	a5,384(s1)
    80002e14:	e791                	bnez	a5,80002e20 <usertrap+0xf2>
    80002e16:	1984a703          	lw	a4,408(s1)
    80002e1a:	4785                	li	a5,1
    80002e1c:	00f70e63          	beq	a4,a5,80002e38 <usertrap+0x10a>
  if (killed(p))
    80002e20:	8526                	mv	a0,s1
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	89a080e7          	jalr	-1894(ra) # 800026bc <killed>
    80002e2a:	cd41                	beqz	a0,80002ec2 <usertrap+0x194>
    exit(-1);
    80002e2c:	557d                	li	a0,-1
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	70e080e7          	jalr	1806(ra) # 8000253c <exit>
  if (which_dev == 2)
    80002e36:	a071                	j	80002ec2 <usertrap+0x194>
      struct trapframe *tf = kalloc();
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	e1c080e7          	jalr	-484(ra) # 80000c54 <kalloc>
    80002e40:	892a                	mv	s2,a0
      memmove(tf, p->trapframe, PGSIZE);
    80002e42:	6605                	lui	a2,0x1
    80002e44:	6cac                	ld	a1,88(s1)
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	094080e7          	jalr	148(ra) # 80000eda <memmove>
      p->alarm_tf = tf;
    80002e4e:	1924b423          	sd	s2,392(s1)
      p->currentticks++;
    80002e52:	17c4a783          	lw	a5,380(s1)
    80002e56:	2785                	addiw	a5,a5,1
    80002e58:	0007871b          	sext.w	a4,a5
    80002e5c:	16f4ae23          	sw	a5,380(s1)
      if (p->currentticks >= p->alarmticks)
    80002e60:	1784a783          	lw	a5,376(s1)
    80002e64:	faf74ee3          	blt	a4,a5,80002e20 <usertrap+0xf2>
        p->alarmset = 1;
    80002e68:	4785                	li	a5,1
    80002e6a:	18f4a023          	sw	a5,384(s1)
        p->trapframe->epc = p->handler;
    80002e6e:	6cbc                	ld	a5,88(s1)
    80002e70:	1904b703          	ld	a4,400(s1)
    80002e74:	ef98                	sd	a4,24(a5)
    80002e76:	b76d                	j	80002e20 <usertrap+0xf2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e78:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e7c:	5890                	lw	a2,48(s1)
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	56a50513          	addi	a0,a0,1386 # 800083e8 <states.0+0xf8>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	704080e7          	jalr	1796(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e92:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e96:	00005517          	auipc	a0,0x5
    80002e9a:	58250513          	addi	a0,a0,1410 # 80008418 <states.0+0x128>
    80002e9e:	ffffd097          	auipc	ra,0xffffd
    80002ea2:	6ec080e7          	jalr	1772(ra) # 8000058a <printf>
    setkilled(p);
    80002ea6:	8526                	mv	a0,s1
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	7e8080e7          	jalr	2024(ra) # 80002690 <setkilled>
    80002eb0:	bde1                	j	80002d88 <usertrap+0x5a>
    exit(-1);
    80002eb2:	557d                	li	a0,-1
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	688080e7          	jalr	1672(ra) # 8000253c <exit>
  if (which_dev == 2)
    80002ebc:	4789                	li	a5,2
    80002ebe:	ecf91ce3          	bne	s2,a5,80002d96 <usertrap+0x68>
    yield();
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	3be080e7          	jalr	958(ra) # 80002280 <yield>
    80002eca:	b5f1                	j	80002d96 <usertrap+0x68>

0000000080002ecc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ecc:	1101                	addi	sp,sp,-32
    80002ece:	ec06                	sd	ra,24(sp)
    80002ed0:	e822                	sd	s0,16(sp)
    80002ed2:	e426                	sd	s1,8(sp)
    80002ed4:	1000                	addi	s0,sp,32
    80002ed6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	caa080e7          	jalr	-854(ra) # 80001b82 <myproc>
  switch (n)
    80002ee0:	4795                	li	a5,5
    80002ee2:	0497e163          	bltu	a5,s1,80002f24 <argraw+0x58>
    80002ee6:	048a                	slli	s1,s1,0x2
    80002ee8:	00005717          	auipc	a4,0x5
    80002eec:	69070713          	addi	a4,a4,1680 # 80008578 <states.0+0x288>
    80002ef0:	94ba                	add	s1,s1,a4
    80002ef2:	409c                	lw	a5,0(s1)
    80002ef4:	97ba                	add	a5,a5,a4
    80002ef6:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002ef8:	6d3c                	ld	a5,88(a0)
    80002efa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	64a2                	ld	s1,8(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret
    return p->trapframe->a1;
    80002f06:	6d3c                	ld	a5,88(a0)
    80002f08:	7fa8                	ld	a0,120(a5)
    80002f0a:	bfcd                	j	80002efc <argraw+0x30>
    return p->trapframe->a2;
    80002f0c:	6d3c                	ld	a5,88(a0)
    80002f0e:	63c8                	ld	a0,128(a5)
    80002f10:	b7f5                	j	80002efc <argraw+0x30>
    return p->trapframe->a3;
    80002f12:	6d3c                	ld	a5,88(a0)
    80002f14:	67c8                	ld	a0,136(a5)
    80002f16:	b7dd                	j	80002efc <argraw+0x30>
    return p->trapframe->a4;
    80002f18:	6d3c                	ld	a5,88(a0)
    80002f1a:	6bc8                	ld	a0,144(a5)
    80002f1c:	b7c5                	j	80002efc <argraw+0x30>
    return p->trapframe->a5;
    80002f1e:	6d3c                	ld	a5,88(a0)
    80002f20:	6fc8                	ld	a0,152(a5)
    80002f22:	bfe9                	j	80002efc <argraw+0x30>
  panic("argraw");
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	51450513          	addi	a0,a0,1300 # 80008438 <states.0+0x148>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	614080e7          	jalr	1556(ra) # 80000540 <panic>

0000000080002f34 <fetchaddr>:
{
    80002f34:	1101                	addi	sp,sp,-32
    80002f36:	ec06                	sd	ra,24(sp)
    80002f38:	e822                	sd	s0,16(sp)
    80002f3a:	e426                	sd	s1,8(sp)
    80002f3c:	e04a                	sd	s2,0(sp)
    80002f3e:	1000                	addi	s0,sp,32
    80002f40:	84aa                	mv	s1,a0
    80002f42:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	c3e080e7          	jalr	-962(ra) # 80001b82 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f4c:	653c                	ld	a5,72(a0)
    80002f4e:	02f4f863          	bgeu	s1,a5,80002f7e <fetchaddr+0x4a>
    80002f52:	00848713          	addi	a4,s1,8
    80002f56:	02e7e663          	bltu	a5,a4,80002f82 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f5a:	46a1                	li	a3,8
    80002f5c:	8626                	mv	a2,s1
    80002f5e:	85ca                	mv	a1,s2
    80002f60:	6928                	ld	a0,80(a0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	96c080e7          	jalr	-1684(ra) # 800018ce <copyin>
    80002f6a:	00a03533          	snez	a0,a0
    80002f6e:	40a00533          	neg	a0,a0
}
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	64a2                	ld	s1,8(sp)
    80002f78:	6902                	ld	s2,0(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret
    return -1;
    80002f7e:	557d                	li	a0,-1
    80002f80:	bfcd                	j	80002f72 <fetchaddr+0x3e>
    80002f82:	557d                	li	a0,-1
    80002f84:	b7fd                	j	80002f72 <fetchaddr+0x3e>

0000000080002f86 <fetchstr>:
{
    80002f86:	7179                	addi	sp,sp,-48
    80002f88:	f406                	sd	ra,40(sp)
    80002f8a:	f022                	sd	s0,32(sp)
    80002f8c:	ec26                	sd	s1,24(sp)
    80002f8e:	e84a                	sd	s2,16(sp)
    80002f90:	e44e                	sd	s3,8(sp)
    80002f92:	1800                	addi	s0,sp,48
    80002f94:	892a                	mv	s2,a0
    80002f96:	84ae                	mv	s1,a1
    80002f98:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	be8080e7          	jalr	-1048(ra) # 80001b82 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fa2:	86ce                	mv	a3,s3
    80002fa4:	864a                	mv	a2,s2
    80002fa6:	85a6                	mv	a1,s1
    80002fa8:	6928                	ld	a0,80(a0)
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	9b2080e7          	jalr	-1614(ra) # 8000195c <copyinstr>
    80002fb2:	00054e63          	bltz	a0,80002fce <fetchstr+0x48>
  return strlen(buf);
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	042080e7          	jalr	66(ra) # 80000ffa <strlen>
}
    80002fc0:	70a2                	ld	ra,40(sp)
    80002fc2:	7402                	ld	s0,32(sp)
    80002fc4:	64e2                	ld	s1,24(sp)
    80002fc6:	6942                	ld	s2,16(sp)
    80002fc8:	69a2                	ld	s3,8(sp)
    80002fca:	6145                	addi	sp,sp,48
    80002fcc:	8082                	ret
    return -1;
    80002fce:	557d                	li	a0,-1
    80002fd0:	bfc5                	j	80002fc0 <fetchstr+0x3a>

0000000080002fd2 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fd2:	1101                	addi	sp,sp,-32
    80002fd4:	ec06                	sd	ra,24(sp)
    80002fd6:	e822                	sd	s0,16(sp)
    80002fd8:	e426                	sd	s1,8(sp)
    80002fda:	1000                	addi	s0,sp,32
    80002fdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fde:	00000097          	auipc	ra,0x0
    80002fe2:	eee080e7          	jalr	-274(ra) # 80002ecc <argraw>
    80002fe6:	c088                	sw	a0,0(s1)
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6105                	addi	sp,sp,32
    80002ff0:	8082                	ret

0000000080002ff2 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	e426                	sd	s1,8(sp)
    80002ffa:	1000                	addi	s0,sp,32
    80002ffc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	ece080e7          	jalr	-306(ra) # 80002ecc <argraw>
    80003006:	e088                	sd	a0,0(s1)
}
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003012:	7179                	addi	sp,sp,-48
    80003014:	f406                	sd	ra,40(sp)
    80003016:	f022                	sd	s0,32(sp)
    80003018:	ec26                	sd	s1,24(sp)
    8000301a:	e84a                	sd	s2,16(sp)
    8000301c:	1800                	addi	s0,sp,48
    8000301e:	84ae                	mv	s1,a1
    80003020:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003022:	fd840593          	addi	a1,s0,-40
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	fcc080e7          	jalr	-52(ra) # 80002ff2 <argaddr>
  return fetchstr(addr, buf, max);
    8000302e:	864a                	mv	a2,s2
    80003030:	85a6                	mv	a1,s1
    80003032:	fd843503          	ld	a0,-40(s0)
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	f50080e7          	jalr	-176(ra) # 80002f86 <fetchstr>
}
    8000303e:	70a2                	ld	ra,40(sp)
    80003040:	7402                	ld	s0,32(sp)
    80003042:	64e2                	ld	s1,24(sp)
    80003044:	6942                	ld	s2,16(sp)
    80003046:	6145                	addi	sp,sp,48
    80003048:	8082                	ret

000000008000304a <syscall>:
    [SYS_sigalarm] sys_sigalarm,
    [SYS_sigreturn] sys_sigreturn,
};

void syscall(void)
{
    8000304a:	7139                	addi	sp,sp,-64
    8000304c:	fc06                	sd	ra,56(sp)
    8000304e:	f822                	sd	s0,48(sp)
    80003050:	f426                	sd	s1,40(sp)
    80003052:	f04a                	sd	s2,32(sp)
    80003054:	ec4e                	sd	s3,24(sp)
    80003056:	e852                	sd	s4,16(sp)
    80003058:	e456                	sd	s5,8(sp)
    8000305a:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    8000305c:	fffff097          	auipc	ra,0xfffff
    80003060:	b26080e7          	jalr	-1242(ra) # 80001b82 <myproc>
    80003064:	89aa                	mv	s3,a0

  num = p->trapframe->a7;
    80003066:	05853a03          	ld	s4,88(a0)
    8000306a:	0a8a3783          	ld	a5,168(s4)
    8000306e:	0007891b          	sext.w	s2,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003072:	37fd                	addiw	a5,a5,-1
    80003074:	4769                	li	a4,26
    80003076:	0af76663          	bltu	a4,a5,80003122 <syscall+0xd8>
    8000307a:	00391713          	slli	a4,s2,0x3
    8000307e:	00005797          	auipc	a5,0x5
    80003082:	51278793          	addi	a5,a5,1298 # 80008590 <syscalls>
    80003086:	97ba                	add	a5,a5,a4
    80003088:	6398                	ld	a4,0(a5)
    8000308a:	cf41                	beqz	a4,80003122 <syscall+0xd8>
  {
    int sys_number = 1;
    for (int i = 0; i < num; i++)
    8000308c:	09205963          	blez	s2,8000311e <syscall+0xd4>
    80003090:	4781                	li	a5,0
    int sys_number = 1;
    80003092:	4485                	li	s1,1
      sys_number *= 2;
    80003094:	0014949b          	slliw	s1,s1,0x1
    for (int i = 0; i < num; i++)
    80003098:	2785                	addiw	a5,a5,1
    8000309a:	fef91de3          	bne	s2,a5,80003094 <syscall+0x4a>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    int arg1 = p->trapframe->a0;
    8000309e:	070a3a83          	ld	s5,112(s4)
    p->trapframe->a0 = syscalls[num]();
    800030a2:	9702                	jalr	a4
    800030a4:	06aa3823          	sd	a0,112(s4)
    if (p->mask & sys_number)
    800030a8:	1749a783          	lw	a5,372(s3)
    800030ac:	8cfd                	and	s1,s1,a5
    800030ae:	c8d9                	beqz	s1,80003144 <syscall+0xfa>
    {
      printf("%d: syscall %s (%d ", p->pid, syscallnames[num].name, arg1);
    800030b0:	0912                	slli	s2,s2,0x4
    800030b2:	00005497          	auipc	s1,0x5
    800030b6:	4de48493          	addi	s1,s1,1246 # 80008590 <syscalls>
    800030ba:	94ca                	add	s1,s1,s2
    800030bc:	000a869b          	sext.w	a3,s5
    800030c0:	70f0                	ld	a2,224(s1)
    800030c2:	0309a583          	lw	a1,48(s3)
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	37a50513          	addi	a0,a0,890 # 80008440 <states.0+0x150>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	4bc080e7          	jalr	1212(ra) # 8000058a <printf>
      for (int i = 1; i < syscallnames[num].num_of_args; i++)
    800030d6:	0e84a903          	lw	s2,232(s1)
    800030da:	4785                	li	a5,1
    800030dc:	0327d563          	bge	a5,s2,80003106 <syscall+0xbc>
    800030e0:	4485                	li	s1,1
      {
        // printf("\nlog %d\n", i);
        printf("%d ", argraw(i));
    800030e2:	00005a17          	auipc	s4,0x5
    800030e6:	36ea0a13          	addi	s4,s4,878 # 80008450 <states.0+0x160>
    800030ea:	8526                	mv	a0,s1
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	de0080e7          	jalr	-544(ra) # 80002ecc <argraw>
    800030f4:	85aa                	mv	a1,a0
    800030f6:	8552                	mv	a0,s4
    800030f8:	ffffd097          	auipc	ra,0xffffd
    800030fc:	492080e7          	jalr	1170(ra) # 8000058a <printf>
      for (int i = 1; i < syscallnames[num].num_of_args; i++)
    80003100:	2485                	addiw	s1,s1,1
    80003102:	ff2494e3          	bne	s1,s2,800030ea <syscall+0xa0>
      }
      printf(") -> %d\n", p->trapframe->a0);
    80003106:	0589b783          	ld	a5,88(s3)
    8000310a:	7bac                	ld	a1,112(a5)
    8000310c:	00005517          	auipc	a0,0x5
    80003110:	34c50513          	addi	a0,a0,844 # 80008458 <states.0+0x168>
    80003114:	ffffd097          	auipc	ra,0xffffd
    80003118:	476080e7          	jalr	1142(ra) # 8000058a <printf>
    8000311c:	a025                	j	80003144 <syscall+0xfa>
    int sys_number = 1;
    8000311e:	4485                	li	s1,1
    80003120:	bfbd                	j	8000309e <syscall+0x54>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003122:	86ca                	mv	a3,s2
    80003124:	15898613          	addi	a2,s3,344
    80003128:	0309a583          	lw	a1,48(s3)
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	33c50513          	addi	a0,a0,828 # 80008468 <states.0+0x178>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	456080e7          	jalr	1110(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000313c:	0589b783          	ld	a5,88(s3)
    80003140:	577d                	li	a4,-1
    80003142:	fbb8                	sd	a4,112(a5)
  }
}
    80003144:	70e2                	ld	ra,56(sp)
    80003146:	7442                	ld	s0,48(sp)
    80003148:	74a2                	ld	s1,40(sp)
    8000314a:	7902                	ld	s2,32(sp)
    8000314c:	69e2                	ld	s3,24(sp)
    8000314e:	6a42                	ld	s4,16(sp)
    80003150:	6aa2                	ld	s5,8(sp)
    80003152:	6121                	addi	sp,sp,64
    80003154:	8082                	ret

0000000080003156 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000315e:	fec40593          	addi	a1,s0,-20
    80003162:	4501                	li	a0,0
    80003164:	00000097          	auipc	ra,0x0
    80003168:	e6e080e7          	jalr	-402(ra) # 80002fd2 <argint>
  exit(n);
    8000316c:	fec42503          	lw	a0,-20(s0)
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	3cc080e7          	jalr	972(ra) # 8000253c <exit>
  return 0; // not reached
}
    80003178:	4501                	li	a0,0
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	6105                	addi	sp,sp,32
    80003180:	8082                	ret

0000000080003182 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003182:	1141                	addi	sp,sp,-16
    80003184:	e406                	sd	ra,8(sp)
    80003186:	e022                	sd	s0,0(sp)
    80003188:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000318a:	fffff097          	auipc	ra,0xfffff
    8000318e:	9f8080e7          	jalr	-1544(ra) # 80001b82 <myproc>
}
    80003192:	5908                	lw	a0,48(a0)
    80003194:	60a2                	ld	ra,8(sp)
    80003196:	6402                	ld	s0,0(sp)
    80003198:	0141                	addi	sp,sp,16
    8000319a:	8082                	ret

000000008000319c <sys_fork>:

uint64
sys_fork(void)
{
    8000319c:	1141                	addi	sp,sp,-16
    8000319e:	e406                	sd	ra,8(sp)
    800031a0:	e022                	sd	s0,0(sp)
    800031a2:	0800                	addi	s0,sp,16
  return fork();
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	dc0080e7          	jalr	-576(ra) # 80001f64 <fork>
}
    800031ac:	60a2                	ld	ra,8(sp)
    800031ae:	6402                	ld	s0,0(sp)
    800031b0:	0141                	addi	sp,sp,16
    800031b2:	8082                	ret

00000000800031b4 <sys_wait>:

uint64
sys_wait(void)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800031bc:	fe840593          	addi	a1,s0,-24
    800031c0:	4501                	li	a0,0
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	e30080e7          	jalr	-464(ra) # 80002ff2 <argaddr>
  return wait(p);
    800031ca:	fe843503          	ld	a0,-24(s0)
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	520080e7          	jalr	1312(ra) # 800026ee <wait>
}
    800031d6:	60e2                	ld	ra,24(sp)
    800031d8:	6442                	ld	s0,16(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret

00000000800031de <sys_waitx>:

uint64
sys_waitx(void)
{
    800031de:	7139                	addi	sp,sp,-64
    800031e0:	fc06                	sd	ra,56(sp)
    800031e2:	f822                	sd	s0,48(sp)
    800031e4:	f426                	sd	s1,40(sp)
    800031e6:	f04a                	sd	s2,32(sp)
    800031e8:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800031ea:	fd840593          	addi	a1,s0,-40
    800031ee:	4501                	li	a0,0
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	e02080e7          	jalr	-510(ra) # 80002ff2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800031f8:	fd040593          	addi	a1,s0,-48
    800031fc:	4505                	li	a0,1
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	df4080e7          	jalr	-524(ra) # 80002ff2 <argaddr>
  argaddr(2, &addr2);
    80003206:	fc840593          	addi	a1,s0,-56
    8000320a:	4509                	li	a0,2
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	de6080e7          	jalr	-538(ra) # 80002ff2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003214:	fc040613          	addi	a2,s0,-64
    80003218:	fc440593          	addi	a1,s0,-60
    8000321c:	fd843503          	ld	a0,-40(s0)
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	100080e7          	jalr	256(ra) # 80002320 <waitx>
    80003228:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	958080e7          	jalr	-1704(ra) # 80001b82 <myproc>
    80003232:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003234:	4691                	li	a3,4
    80003236:	fc440613          	addi	a2,s0,-60
    8000323a:	fd043583          	ld	a1,-48(s0)
    8000323e:	6928                	ld	a0,80(a0)
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	5ce080e7          	jalr	1486(ra) # 8000180e <copyout>
    return -1;
    80003248:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000324a:	00054f63          	bltz	a0,80003268 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000324e:	4691                	li	a3,4
    80003250:	fc040613          	addi	a2,s0,-64
    80003254:	fc843583          	ld	a1,-56(s0)
    80003258:	68a8                	ld	a0,80(s1)
    8000325a:	ffffe097          	auipc	ra,0xffffe
    8000325e:	5b4080e7          	jalr	1460(ra) # 8000180e <copyout>
    80003262:	00054a63          	bltz	a0,80003276 <sys_waitx+0x98>
    return -1;
  return ret;
    80003266:	87ca                	mv	a5,s2
}
    80003268:	853e                	mv	a0,a5
    8000326a:	70e2                	ld	ra,56(sp)
    8000326c:	7442                	ld	s0,48(sp)
    8000326e:	74a2                	ld	s1,40(sp)
    80003270:	7902                	ld	s2,32(sp)
    80003272:	6121                	addi	sp,sp,64
    80003274:	8082                	ret
    return -1;
    80003276:	57fd                	li	a5,-1
    80003278:	bfc5                	j	80003268 <sys_waitx+0x8a>

000000008000327a <sys_set_tickets>:

uint64
sys_set_tickets(void)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	1000                	addi	s0,sp,32
  int number = 1;
    80003282:	4785                	li	a5,1
    80003284:	fef42623          	sw	a5,-20(s0)
  argint(0, &number);
    80003288:	fec40593          	addi	a1,s0,-20
    8000328c:	4501                	li	a0,0
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	d44080e7          	jalr	-700(ra) # 80002fd2 <argint>

  return set_tickets(number);
    80003296:	fec42503          	lw	a0,-20(s0)
    8000329a:	fffff097          	auipc	ra,0xfffff
    8000329e:	6ec080e7          	jalr	1772(ra) # 80002986 <set_tickets>
}
    800032a2:	60e2                	ld	ra,24(sp)
    800032a4:	6442                	ld	s0,16(sp)
    800032a6:	6105                	addi	sp,sp,32
    800032a8:	8082                	ret

00000000800032aa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032aa:	7179                	addi	sp,sp,-48
    800032ac:	f406                	sd	ra,40(sp)
    800032ae:	f022                	sd	s0,32(sp)
    800032b0:	ec26                	sd	s1,24(sp)
    800032b2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800032b4:	fdc40593          	addi	a1,s0,-36
    800032b8:	4501                	li	a0,0
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	d18080e7          	jalr	-744(ra) # 80002fd2 <argint>
  addr = myproc()->sz;
    800032c2:	fffff097          	auipc	ra,0xfffff
    800032c6:	8c0080e7          	jalr	-1856(ra) # 80001b82 <myproc>
    800032ca:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800032cc:	fdc42503          	lw	a0,-36(s0)
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	c38080e7          	jalr	-968(ra) # 80001f08 <growproc>
    800032d8:	00054863          	bltz	a0,800032e8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800032dc:	8526                	mv	a0,s1
    800032de:	70a2                	ld	ra,40(sp)
    800032e0:	7402                	ld	s0,32(sp)
    800032e2:	64e2                	ld	s1,24(sp)
    800032e4:	6145                	addi	sp,sp,48
    800032e6:	8082                	ret
    return -1;
    800032e8:	54fd                	li	s1,-1
    800032ea:	bfcd                	j	800032dc <sys_sbrk+0x32>

00000000800032ec <sys_sleep>:

uint64
sys_sleep(void)
{
    800032ec:	7139                	addi	sp,sp,-64
    800032ee:	fc06                	sd	ra,56(sp)
    800032f0:	f822                	sd	s0,48(sp)
    800032f2:	f426                	sd	s1,40(sp)
    800032f4:	f04a                	sd	s2,32(sp)
    800032f6:	ec4e                	sd	s3,24(sp)
    800032f8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800032fa:	fcc40593          	addi	a1,s0,-52
    800032fe:	4501                	li	a0,0
    80003300:	00000097          	auipc	ra,0x0
    80003304:	cd2080e7          	jalr	-814(ra) # 80002fd2 <argint>
  acquire(&tickslock);
    80003308:	00234517          	auipc	a0,0x234
    8000330c:	7a850513          	addi	a0,a0,1960 # 80237ab0 <tickslock>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	a72080e7          	jalr	-1422(ra) # 80000d82 <acquire>
  ticks0 = ticks;
    80003318:	00006917          	auipc	s2,0x6
    8000331c:	8f892903          	lw	s2,-1800(s2) # 80008c10 <ticks>
  while (ticks - ticks0 < n)
    80003320:	fcc42783          	lw	a5,-52(s0)
    80003324:	cf9d                	beqz	a5,80003362 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003326:	00234997          	auipc	s3,0x234
    8000332a:	78a98993          	addi	s3,s3,1930 # 80237ab0 <tickslock>
    8000332e:	00006497          	auipc	s1,0x6
    80003332:	8e248493          	addi	s1,s1,-1822 # 80008c10 <ticks>
    if (killed(myproc()))
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	84c080e7          	jalr	-1972(ra) # 80001b82 <myproc>
    8000333e:	fffff097          	auipc	ra,0xfffff
    80003342:	37e080e7          	jalr	894(ra) # 800026bc <killed>
    80003346:	ed15                	bnez	a0,80003382 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003348:	85ce                	mv	a1,s3
    8000334a:	8526                	mv	a0,s1
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	f70080e7          	jalr	-144(ra) # 800022bc <sleep>
  while (ticks - ticks0 < n)
    80003354:	409c                	lw	a5,0(s1)
    80003356:	412787bb          	subw	a5,a5,s2
    8000335a:	fcc42703          	lw	a4,-52(s0)
    8000335e:	fce7ece3          	bltu	a5,a4,80003336 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003362:	00234517          	auipc	a0,0x234
    80003366:	74e50513          	addi	a0,a0,1870 # 80237ab0 <tickslock>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	acc080e7          	jalr	-1332(ra) # 80000e36 <release>
  return 0;
    80003372:	4501                	li	a0,0
}
    80003374:	70e2                	ld	ra,56(sp)
    80003376:	7442                	ld	s0,48(sp)
    80003378:	74a2                	ld	s1,40(sp)
    8000337a:	7902                	ld	s2,32(sp)
    8000337c:	69e2                	ld	s3,24(sp)
    8000337e:	6121                	addi	sp,sp,64
    80003380:	8082                	ret
      release(&tickslock);
    80003382:	00234517          	auipc	a0,0x234
    80003386:	72e50513          	addi	a0,a0,1838 # 80237ab0 <tickslock>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	aac080e7          	jalr	-1364(ra) # 80000e36 <release>
      return -1;
    80003392:	557d                	li	a0,-1
    80003394:	b7c5                	j	80003374 <sys_sleep+0x88>

0000000080003396 <sys_kill>:

uint64
sys_kill(void)
{
    80003396:	1101                	addi	sp,sp,-32
    80003398:	ec06                	sd	ra,24(sp)
    8000339a:	e822                	sd	s0,16(sp)
    8000339c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000339e:	fec40593          	addi	a1,s0,-20
    800033a2:	4501                	li	a0,0
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	c2e080e7          	jalr	-978(ra) # 80002fd2 <argint>
  return kill(pid);
    800033ac:	fec42503          	lw	a0,-20(s0)
    800033b0:	fffff097          	auipc	ra,0xfffff
    800033b4:	26e080e7          	jalr	622(ra) # 8000261e <kill>
}
    800033b8:	60e2                	ld	ra,24(sp)
    800033ba:	6442                	ld	s0,16(sp)
    800033bc:	6105                	addi	sp,sp,32
    800033be:	8082                	ret

00000000800033c0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033c0:	1101                	addi	sp,sp,-32
    800033c2:	ec06                	sd	ra,24(sp)
    800033c4:	e822                	sd	s0,16(sp)
    800033c6:	e426                	sd	s1,8(sp)
    800033c8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033ca:	00234517          	auipc	a0,0x234
    800033ce:	6e650513          	addi	a0,a0,1766 # 80237ab0 <tickslock>
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	9b0080e7          	jalr	-1616(ra) # 80000d82 <acquire>
  xticks = ticks;
    800033da:	00006497          	auipc	s1,0x6
    800033de:	8364a483          	lw	s1,-1994(s1) # 80008c10 <ticks>
  release(&tickslock);
    800033e2:	00234517          	auipc	a0,0x234
    800033e6:	6ce50513          	addi	a0,a0,1742 # 80237ab0 <tickslock>
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	a4c080e7          	jalr	-1460(ra) # 80000e36 <release>
  return xticks;
}
    800033f2:	02049513          	slli	a0,s1,0x20
    800033f6:	9101                	srli	a0,a0,0x20
    800033f8:	60e2                	ld	ra,24(sp)
    800033fa:	6442                	ld	s0,16(sp)
    800033fc:	64a2                	ld	s1,8(sp)
    800033fe:	6105                	addi	sp,sp,32
    80003400:	8082                	ret

0000000080003402 <sys_trace>:

uint64
sys_trace(void)
{
    80003402:	1141                	addi	sp,sp,-16
    80003404:	e406                	sd	ra,8(sp)
    80003406:	e022                	sd	s0,0(sp)
    80003408:	0800                	addi	s0,sp,16
  argint(0, &myproc()->mask);
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	778080e7          	jalr	1912(ra) # 80001b82 <myproc>
    80003412:	17450593          	addi	a1,a0,372
    80003416:	4501                	li	a0,0
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	bba080e7          	jalr	-1094(ra) # 80002fd2 <argint>
  return 0;
}
    80003420:	4501                	li	a0,0
    80003422:	60a2                	ld	ra,8(sp)
    80003424:	6402                	ld	s0,0(sp)
    80003426:	0141                	addi	sp,sp,16
    80003428:	8082                	ret

000000008000342a <sys_set_priority>:

uint64
sys_set_priority(void)
{
    8000342a:	1101                	addi	sp,sp,-32
    8000342c:	ec06                	sd	ra,24(sp)
    8000342e:	e822                	sd	s0,16(sp)
    80003430:	1000                	addi	s0,sp,32
  int new_priority, pid;
  argint(0, &new_priority);
    80003432:	fec40593          	addi	a1,s0,-20
    80003436:	4501                	li	a0,0
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	b9a080e7          	jalr	-1126(ra) # 80002fd2 <argint>
  argint(1, &pid);
    80003440:	fe840593          	addi	a1,s0,-24
    80003444:	4505                	li	a0,1
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	b8c080e7          	jalr	-1140(ra) # 80002fd2 <argint>
  return setpriority(new_priority, pid);
    8000344e:	fe842583          	lw	a1,-24(s0)
    80003452:	fec42503          	lw	a0,-20(s0)
    80003456:	fffff097          	auipc	ra,0xfffff
    8000345a:	522080e7          	jalr	1314(ra) # 80002978 <setpriority>
}
    8000345e:	60e2                	ld	ra,24(sp)
    80003460:	6442                	ld	s0,16(sp)
    80003462:	6105                	addi	sp,sp,32
    80003464:	8082                	ret

0000000080003466 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80003466:	1101                	addi	sp,sp,-32
    80003468:	ec06                	sd	ra,24(sp)
    8000346a:	e822                	sd	s0,16(sp)
    8000346c:	1000                	addi	s0,sp,32
  uint64 addr;
  int interval;

  argint(0, &interval);
    8000346e:	fe440593          	addi	a1,s0,-28
    80003472:	4501                	li	a0,0
    80003474:	00000097          	auipc	ra,0x0
    80003478:	b5e080e7          	jalr	-1186(ra) # 80002fd2 <argint>
  argaddr(1, &addr);
    8000347c:	fe840593          	addi	a1,s0,-24
    80003480:	4505                	li	a0,1
    80003482:	00000097          	auipc	ra,0x0
    80003486:	b70080e7          	jalr	-1168(ra) # 80002ff2 <argaddr>

  if (interval <= 0)
    8000348a:	fe442783          	lw	a5,-28(s0)
    8000348e:	02f05663          	blez	a5,800034ba <sys_sigalarm+0x54>
  {
    myproc()->alarm_called = 0;
    return 0;
  }
  struct proc *p = myproc();
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	6f0080e7          	jalr	1776(ra) # 80001b82 <myproc>

  p->alarmticks = interval;
    8000349a:	fe442783          	lw	a5,-28(s0)
    8000349e:	16f52c23          	sw	a5,376(a0)
  p->handler = addr;
    800034a2:	fe843783          	ld	a5,-24(s0)
    800034a6:	18f53823          	sd	a5,400(a0)
  p->alarm_called = 1;
    800034aa:	4785                	li	a5,1
    800034ac:	18f52c23          	sw	a5,408(a0)

  return 0;
}
    800034b0:	4501                	li	a0,0
    800034b2:	60e2                	ld	ra,24(sp)
    800034b4:	6442                	ld	s0,16(sp)
    800034b6:	6105                	addi	sp,sp,32
    800034b8:	8082                	ret
    myproc()->alarm_called = 0;
    800034ba:	ffffe097          	auipc	ra,0xffffe
    800034be:	6c8080e7          	jalr	1736(ra) # 80001b82 <myproc>
    800034c2:	18052c23          	sw	zero,408(a0)
    return 0;
    800034c6:	b7ed                	j	800034b0 <sys_sigalarm+0x4a>

00000000800034c8 <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    800034c8:	1101                	addi	sp,sp,-32
    800034ca:	ec06                	sd	ra,24(sp)
    800034cc:	e822                	sd	s0,16(sp)
    800034ce:	e426                	sd	s1,8(sp)
    800034d0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800034d2:	ffffe097          	auipc	ra,0xffffe
    800034d6:	6b0080e7          	jalr	1712(ra) # 80001b82 <myproc>
    800034da:	84aa                	mv	s1,a0
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
    800034dc:	6605                	lui	a2,0x1
    800034de:	18853583          	ld	a1,392(a0)
    800034e2:	6d28                	ld	a0,88(a0)
    800034e4:	ffffe097          	auipc	ra,0xffffe
    800034e8:	9f6080e7          	jalr	-1546(ra) # 80000eda <memmove>
  kfree(p->alarm_tf);
    800034ec:	1884b503          	ld	a0,392(s1)
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	5c4080e7          	jalr	1476(ra) # 80000ab4 <kfree>
  p->alarm_tf = 0;
    800034f8:	1804b423          	sd	zero,392(s1)
  p->alarmset = 0;
    800034fc:	1804a023          	sw	zero,384(s1)
  p->currentticks = 0;
    80003500:	1604ae23          	sw	zero,380(s1)
  return p->trapframe->a0;
    80003504:	6cbc                	ld	a5,88(s1)
    80003506:	7ba8                	ld	a0,112(a5)
    80003508:	60e2                	ld	ra,24(sp)
    8000350a:	6442                	ld	s0,16(sp)
    8000350c:	64a2                	ld	s1,8(sp)
    8000350e:	6105                	addi	sp,sp,32
    80003510:	8082                	ret

0000000080003512 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003512:	7179                	addi	sp,sp,-48
    80003514:	f406                	sd	ra,40(sp)
    80003516:	f022                	sd	s0,32(sp)
    80003518:	ec26                	sd	s1,24(sp)
    8000351a:	e84a                	sd	s2,16(sp)
    8000351c:	e44e                	sd	s3,8(sp)
    8000351e:	e052                	sd	s4,0(sp)
    80003520:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003522:	00005597          	auipc	a1,0x5
    80003526:	30e58593          	addi	a1,a1,782 # 80008830 <syscallnames+0x1c0>
    8000352a:	00234517          	auipc	a0,0x234
    8000352e:	59e50513          	addi	a0,a0,1438 # 80237ac8 <bcache>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	7c0080e7          	jalr	1984(ra) # 80000cf2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000353a:	0023c797          	auipc	a5,0x23c
    8000353e:	58e78793          	addi	a5,a5,1422 # 8023fac8 <bcache+0x8000>
    80003542:	0023c717          	auipc	a4,0x23c
    80003546:	7ee70713          	addi	a4,a4,2030 # 8023fd30 <bcache+0x8268>
    8000354a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000354e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003552:	00234497          	auipc	s1,0x234
    80003556:	58e48493          	addi	s1,s1,1422 # 80237ae0 <bcache+0x18>
    b->next = bcache.head.next;
    8000355a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000355c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000355e:	00005a17          	auipc	s4,0x5
    80003562:	2daa0a13          	addi	s4,s4,730 # 80008838 <syscallnames+0x1c8>
    b->next = bcache.head.next;
    80003566:	2b893783          	ld	a5,696(s2)
    8000356a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000356c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003570:	85d2                	mv	a1,s4
    80003572:	01048513          	addi	a0,s1,16
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	4c8080e7          	jalr	1224(ra) # 80004a3e <initsleeplock>
    bcache.head.next->prev = b;
    8000357e:	2b893783          	ld	a5,696(s2)
    80003582:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003584:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003588:	45848493          	addi	s1,s1,1112
    8000358c:	fd349de3          	bne	s1,s3,80003566 <binit+0x54>
  }
}
    80003590:	70a2                	ld	ra,40(sp)
    80003592:	7402                	ld	s0,32(sp)
    80003594:	64e2                	ld	s1,24(sp)
    80003596:	6942                	ld	s2,16(sp)
    80003598:	69a2                	ld	s3,8(sp)
    8000359a:	6a02                	ld	s4,0(sp)
    8000359c:	6145                	addi	sp,sp,48
    8000359e:	8082                	ret

00000000800035a0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035a0:	7179                	addi	sp,sp,-48
    800035a2:	f406                	sd	ra,40(sp)
    800035a4:	f022                	sd	s0,32(sp)
    800035a6:	ec26                	sd	s1,24(sp)
    800035a8:	e84a                	sd	s2,16(sp)
    800035aa:	e44e                	sd	s3,8(sp)
    800035ac:	1800                	addi	s0,sp,48
    800035ae:	892a                	mv	s2,a0
    800035b0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035b2:	00234517          	auipc	a0,0x234
    800035b6:	51650513          	addi	a0,a0,1302 # 80237ac8 <bcache>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	7c8080e7          	jalr	1992(ra) # 80000d82 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035c2:	0023c497          	auipc	s1,0x23c
    800035c6:	7be4b483          	ld	s1,1982(s1) # 8023fd80 <bcache+0x82b8>
    800035ca:	0023c797          	auipc	a5,0x23c
    800035ce:	76678793          	addi	a5,a5,1894 # 8023fd30 <bcache+0x8268>
    800035d2:	02f48f63          	beq	s1,a5,80003610 <bread+0x70>
    800035d6:	873e                	mv	a4,a5
    800035d8:	a021                	j	800035e0 <bread+0x40>
    800035da:	68a4                	ld	s1,80(s1)
    800035dc:	02e48a63          	beq	s1,a4,80003610 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035e0:	449c                	lw	a5,8(s1)
    800035e2:	ff279ce3          	bne	a5,s2,800035da <bread+0x3a>
    800035e6:	44dc                	lw	a5,12(s1)
    800035e8:	ff3799e3          	bne	a5,s3,800035da <bread+0x3a>
      b->refcnt++;
    800035ec:	40bc                	lw	a5,64(s1)
    800035ee:	2785                	addiw	a5,a5,1
    800035f0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035f2:	00234517          	auipc	a0,0x234
    800035f6:	4d650513          	addi	a0,a0,1238 # 80237ac8 <bcache>
    800035fa:	ffffe097          	auipc	ra,0xffffe
    800035fe:	83c080e7          	jalr	-1988(ra) # 80000e36 <release>
      acquiresleep(&b->lock);
    80003602:	01048513          	addi	a0,s1,16
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	472080e7          	jalr	1138(ra) # 80004a78 <acquiresleep>
      return b;
    8000360e:	a8b9                	j	8000366c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003610:	0023c497          	auipc	s1,0x23c
    80003614:	7684b483          	ld	s1,1896(s1) # 8023fd78 <bcache+0x82b0>
    80003618:	0023c797          	auipc	a5,0x23c
    8000361c:	71878793          	addi	a5,a5,1816 # 8023fd30 <bcache+0x8268>
    80003620:	00f48863          	beq	s1,a5,80003630 <bread+0x90>
    80003624:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003626:	40bc                	lw	a5,64(s1)
    80003628:	cf81                	beqz	a5,80003640 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000362a:	64a4                	ld	s1,72(s1)
    8000362c:	fee49de3          	bne	s1,a4,80003626 <bread+0x86>
  panic("bget: no buffers");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	21050513          	addi	a0,a0,528 # 80008840 <syscallnames+0x1d0>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f08080e7          	jalr	-248(ra) # 80000540 <panic>
      b->dev = dev;
    80003640:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003644:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003648:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000364c:	4785                	li	a5,1
    8000364e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003650:	00234517          	auipc	a0,0x234
    80003654:	47850513          	addi	a0,a0,1144 # 80237ac8 <bcache>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	7de080e7          	jalr	2014(ra) # 80000e36 <release>
      acquiresleep(&b->lock);
    80003660:	01048513          	addi	a0,s1,16
    80003664:	00001097          	auipc	ra,0x1
    80003668:	414080e7          	jalr	1044(ra) # 80004a78 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000366c:	409c                	lw	a5,0(s1)
    8000366e:	cb89                	beqz	a5,80003680 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003670:	8526                	mv	a0,s1
    80003672:	70a2                	ld	ra,40(sp)
    80003674:	7402                	ld	s0,32(sp)
    80003676:	64e2                	ld	s1,24(sp)
    80003678:	6942                	ld	s2,16(sp)
    8000367a:	69a2                	ld	s3,8(sp)
    8000367c:	6145                	addi	sp,sp,48
    8000367e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003680:	4581                	li	a1,0
    80003682:	8526                	mv	a0,s1
    80003684:	00003097          	auipc	ra,0x3
    80003688:	fde080e7          	jalr	-34(ra) # 80006662 <virtio_disk_rw>
    b->valid = 1;
    8000368c:	4785                	li	a5,1
    8000368e:	c09c                	sw	a5,0(s1)
  return b;
    80003690:	b7c5                	j	80003670 <bread+0xd0>

0000000080003692 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003692:	1101                	addi	sp,sp,-32
    80003694:	ec06                	sd	ra,24(sp)
    80003696:	e822                	sd	s0,16(sp)
    80003698:	e426                	sd	s1,8(sp)
    8000369a:	1000                	addi	s0,sp,32
    8000369c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000369e:	0541                	addi	a0,a0,16
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	472080e7          	jalr	1138(ra) # 80004b12 <holdingsleep>
    800036a8:	cd01                	beqz	a0,800036c0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036aa:	4585                	li	a1,1
    800036ac:	8526                	mv	a0,s1
    800036ae:	00003097          	auipc	ra,0x3
    800036b2:	fb4080e7          	jalr	-76(ra) # 80006662 <virtio_disk_rw>
}
    800036b6:	60e2                	ld	ra,24(sp)
    800036b8:	6442                	ld	s0,16(sp)
    800036ba:	64a2                	ld	s1,8(sp)
    800036bc:	6105                	addi	sp,sp,32
    800036be:	8082                	ret
    panic("bwrite");
    800036c0:	00005517          	auipc	a0,0x5
    800036c4:	19850513          	addi	a0,a0,408 # 80008858 <syscallnames+0x1e8>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	e78080e7          	jalr	-392(ra) # 80000540 <panic>

00000000800036d0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	e04a                	sd	s2,0(sp)
    800036da:	1000                	addi	s0,sp,32
    800036dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036de:	01050913          	addi	s2,a0,16
    800036e2:	854a                	mv	a0,s2
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	42e080e7          	jalr	1070(ra) # 80004b12 <holdingsleep>
    800036ec:	c92d                	beqz	a0,8000375e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800036ee:	854a                	mv	a0,s2
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	3de080e7          	jalr	990(ra) # 80004ace <releasesleep>

  acquire(&bcache.lock);
    800036f8:	00234517          	auipc	a0,0x234
    800036fc:	3d050513          	addi	a0,a0,976 # 80237ac8 <bcache>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	682080e7          	jalr	1666(ra) # 80000d82 <acquire>
  b->refcnt--;
    80003708:	40bc                	lw	a5,64(s1)
    8000370a:	37fd                	addiw	a5,a5,-1
    8000370c:	0007871b          	sext.w	a4,a5
    80003710:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003712:	eb05                	bnez	a4,80003742 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003714:	68bc                	ld	a5,80(s1)
    80003716:	64b8                	ld	a4,72(s1)
    80003718:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000371a:	64bc                	ld	a5,72(s1)
    8000371c:	68b8                	ld	a4,80(s1)
    8000371e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003720:	0023c797          	auipc	a5,0x23c
    80003724:	3a878793          	addi	a5,a5,936 # 8023fac8 <bcache+0x8000>
    80003728:	2b87b703          	ld	a4,696(a5)
    8000372c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000372e:	0023c717          	auipc	a4,0x23c
    80003732:	60270713          	addi	a4,a4,1538 # 8023fd30 <bcache+0x8268>
    80003736:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003738:	2b87b703          	ld	a4,696(a5)
    8000373c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000373e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003742:	00234517          	auipc	a0,0x234
    80003746:	38650513          	addi	a0,a0,902 # 80237ac8 <bcache>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	6ec080e7          	jalr	1772(ra) # 80000e36 <release>
}
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	64a2                	ld	s1,8(sp)
    80003758:	6902                	ld	s2,0(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret
    panic("brelse");
    8000375e:	00005517          	auipc	a0,0x5
    80003762:	10250513          	addi	a0,a0,258 # 80008860 <syscallnames+0x1f0>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	dda080e7          	jalr	-550(ra) # 80000540 <panic>

000000008000376e <bpin>:

void
bpin(struct buf *b) {
    8000376e:	1101                	addi	sp,sp,-32
    80003770:	ec06                	sd	ra,24(sp)
    80003772:	e822                	sd	s0,16(sp)
    80003774:	e426                	sd	s1,8(sp)
    80003776:	1000                	addi	s0,sp,32
    80003778:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000377a:	00234517          	auipc	a0,0x234
    8000377e:	34e50513          	addi	a0,a0,846 # 80237ac8 <bcache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	600080e7          	jalr	1536(ra) # 80000d82 <acquire>
  b->refcnt++;
    8000378a:	40bc                	lw	a5,64(s1)
    8000378c:	2785                	addiw	a5,a5,1
    8000378e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003790:	00234517          	auipc	a0,0x234
    80003794:	33850513          	addi	a0,a0,824 # 80237ac8 <bcache>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	69e080e7          	jalr	1694(ra) # 80000e36 <release>
}
    800037a0:	60e2                	ld	ra,24(sp)
    800037a2:	6442                	ld	s0,16(sp)
    800037a4:	64a2                	ld	s1,8(sp)
    800037a6:	6105                	addi	sp,sp,32
    800037a8:	8082                	ret

00000000800037aa <bunpin>:

void
bunpin(struct buf *b) {
    800037aa:	1101                	addi	sp,sp,-32
    800037ac:	ec06                	sd	ra,24(sp)
    800037ae:	e822                	sd	s0,16(sp)
    800037b0:	e426                	sd	s1,8(sp)
    800037b2:	1000                	addi	s0,sp,32
    800037b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b6:	00234517          	auipc	a0,0x234
    800037ba:	31250513          	addi	a0,a0,786 # 80237ac8 <bcache>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	5c4080e7          	jalr	1476(ra) # 80000d82 <acquire>
  b->refcnt--;
    800037c6:	40bc                	lw	a5,64(s1)
    800037c8:	37fd                	addiw	a5,a5,-1
    800037ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037cc:	00234517          	auipc	a0,0x234
    800037d0:	2fc50513          	addi	a0,a0,764 # 80237ac8 <bcache>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	662080e7          	jalr	1634(ra) # 80000e36 <release>
}
    800037dc:	60e2                	ld	ra,24(sp)
    800037de:	6442                	ld	s0,16(sp)
    800037e0:	64a2                	ld	s1,8(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret

00000000800037e6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	e04a                	sd	s2,0(sp)
    800037f0:	1000                	addi	s0,sp,32
    800037f2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037f4:	00d5d59b          	srliw	a1,a1,0xd
    800037f8:	0023d797          	auipc	a5,0x23d
    800037fc:	9ac7a783          	lw	a5,-1620(a5) # 802401a4 <sb+0x1c>
    80003800:	9dbd                	addw	a1,a1,a5
    80003802:	00000097          	auipc	ra,0x0
    80003806:	d9e080e7          	jalr	-610(ra) # 800035a0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000380a:	0074f713          	andi	a4,s1,7
    8000380e:	4785                	li	a5,1
    80003810:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003814:	14ce                	slli	s1,s1,0x33
    80003816:	90d9                	srli	s1,s1,0x36
    80003818:	00950733          	add	a4,a0,s1
    8000381c:	05874703          	lbu	a4,88(a4)
    80003820:	00e7f6b3          	and	a3,a5,a4
    80003824:	c69d                	beqz	a3,80003852 <bfree+0x6c>
    80003826:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003828:	94aa                	add	s1,s1,a0
    8000382a:	fff7c793          	not	a5,a5
    8000382e:	8f7d                	and	a4,a4,a5
    80003830:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003834:	00001097          	auipc	ra,0x1
    80003838:	126080e7          	jalr	294(ra) # 8000495a <log_write>
  brelse(bp);
    8000383c:	854a                	mv	a0,s2
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	e92080e7          	jalr	-366(ra) # 800036d0 <brelse>
}
    80003846:	60e2                	ld	ra,24(sp)
    80003848:	6442                	ld	s0,16(sp)
    8000384a:	64a2                	ld	s1,8(sp)
    8000384c:	6902                	ld	s2,0(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret
    panic("freeing free block");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	01650513          	addi	a0,a0,22 # 80008868 <syscallnames+0x1f8>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	ce6080e7          	jalr	-794(ra) # 80000540 <panic>

0000000080003862 <balloc>:
{
    80003862:	711d                	addi	sp,sp,-96
    80003864:	ec86                	sd	ra,88(sp)
    80003866:	e8a2                	sd	s0,80(sp)
    80003868:	e4a6                	sd	s1,72(sp)
    8000386a:	e0ca                	sd	s2,64(sp)
    8000386c:	fc4e                	sd	s3,56(sp)
    8000386e:	f852                	sd	s4,48(sp)
    80003870:	f456                	sd	s5,40(sp)
    80003872:	f05a                	sd	s6,32(sp)
    80003874:	ec5e                	sd	s7,24(sp)
    80003876:	e862                	sd	s8,16(sp)
    80003878:	e466                	sd	s9,8(sp)
    8000387a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000387c:	0023d797          	auipc	a5,0x23d
    80003880:	9107a783          	lw	a5,-1776(a5) # 8024018c <sb+0x4>
    80003884:	cff5                	beqz	a5,80003980 <balloc+0x11e>
    80003886:	8baa                	mv	s7,a0
    80003888:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000388a:	0023db17          	auipc	s6,0x23d
    8000388e:	8feb0b13          	addi	s6,s6,-1794 # 80240188 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003892:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003894:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003896:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003898:	6c89                	lui	s9,0x2
    8000389a:	a061                	j	80003922 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000389c:	97ca                	add	a5,a5,s2
    8000389e:	8e55                	or	a2,a2,a3
    800038a0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	0b4080e7          	jalr	180(ra) # 8000495a <log_write>
        brelse(bp);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	e20080e7          	jalr	-480(ra) # 800036d0 <brelse>
  bp = bread(dev, bno);
    800038b8:	85a6                	mv	a1,s1
    800038ba:	855e                	mv	a0,s7
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	ce4080e7          	jalr	-796(ra) # 800035a0 <bread>
    800038c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038c6:	40000613          	li	a2,1024
    800038ca:	4581                	li	a1,0
    800038cc:	05850513          	addi	a0,a0,88
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	5ae080e7          	jalr	1454(ra) # 80000e7e <memset>
  log_write(bp);
    800038d8:	854a                	mv	a0,s2
    800038da:	00001097          	auipc	ra,0x1
    800038de:	080080e7          	jalr	128(ra) # 8000495a <log_write>
  brelse(bp);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	dec080e7          	jalr	-532(ra) # 800036d0 <brelse>
}
    800038ec:	8526                	mv	a0,s1
    800038ee:	60e6                	ld	ra,88(sp)
    800038f0:	6446                	ld	s0,80(sp)
    800038f2:	64a6                	ld	s1,72(sp)
    800038f4:	6906                	ld	s2,64(sp)
    800038f6:	79e2                	ld	s3,56(sp)
    800038f8:	7a42                	ld	s4,48(sp)
    800038fa:	7aa2                	ld	s5,40(sp)
    800038fc:	7b02                	ld	s6,32(sp)
    800038fe:	6be2                	ld	s7,24(sp)
    80003900:	6c42                	ld	s8,16(sp)
    80003902:	6ca2                	ld	s9,8(sp)
    80003904:	6125                	addi	sp,sp,96
    80003906:	8082                	ret
    brelse(bp);
    80003908:	854a                	mv	a0,s2
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	dc6080e7          	jalr	-570(ra) # 800036d0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003912:	015c87bb          	addw	a5,s9,s5
    80003916:	00078a9b          	sext.w	s5,a5
    8000391a:	004b2703          	lw	a4,4(s6)
    8000391e:	06eaf163          	bgeu	s5,a4,80003980 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003922:	41fad79b          	sraiw	a5,s5,0x1f
    80003926:	0137d79b          	srliw	a5,a5,0x13
    8000392a:	015787bb          	addw	a5,a5,s5
    8000392e:	40d7d79b          	sraiw	a5,a5,0xd
    80003932:	01cb2583          	lw	a1,28(s6)
    80003936:	9dbd                	addw	a1,a1,a5
    80003938:	855e                	mv	a0,s7
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	c66080e7          	jalr	-922(ra) # 800035a0 <bread>
    80003942:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003944:	004b2503          	lw	a0,4(s6)
    80003948:	000a849b          	sext.w	s1,s5
    8000394c:	8762                	mv	a4,s8
    8000394e:	faa4fde3          	bgeu	s1,a0,80003908 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003952:	00777693          	andi	a3,a4,7
    80003956:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000395a:	41f7579b          	sraiw	a5,a4,0x1f
    8000395e:	01d7d79b          	srliw	a5,a5,0x1d
    80003962:	9fb9                	addw	a5,a5,a4
    80003964:	4037d79b          	sraiw	a5,a5,0x3
    80003968:	00f90633          	add	a2,s2,a5
    8000396c:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003970:	00c6f5b3          	and	a1,a3,a2
    80003974:	d585                	beqz	a1,8000389c <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003976:	2705                	addiw	a4,a4,1
    80003978:	2485                	addiw	s1,s1,1
    8000397a:	fd471ae3          	bne	a4,s4,8000394e <balloc+0xec>
    8000397e:	b769                	j	80003908 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003980:	00005517          	auipc	a0,0x5
    80003984:	f0050513          	addi	a0,a0,-256 # 80008880 <syscallnames+0x210>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	c02080e7          	jalr	-1022(ra) # 8000058a <printf>
  return 0;
    80003990:	4481                	li	s1,0
    80003992:	bfa9                	j	800038ec <balloc+0x8a>

0000000080003994 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003994:	7179                	addi	sp,sp,-48
    80003996:	f406                	sd	ra,40(sp)
    80003998:	f022                	sd	s0,32(sp)
    8000399a:	ec26                	sd	s1,24(sp)
    8000399c:	e84a                	sd	s2,16(sp)
    8000399e:	e44e                	sd	s3,8(sp)
    800039a0:	e052                	sd	s4,0(sp)
    800039a2:	1800                	addi	s0,sp,48
    800039a4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039a6:	47ad                	li	a5,11
    800039a8:	02b7e863          	bltu	a5,a1,800039d8 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800039ac:	02059793          	slli	a5,a1,0x20
    800039b0:	01e7d593          	srli	a1,a5,0x1e
    800039b4:	00b504b3          	add	s1,a0,a1
    800039b8:	0504a903          	lw	s2,80(s1)
    800039bc:	06091e63          	bnez	s2,80003a38 <bmap+0xa4>
      addr = balloc(ip->dev);
    800039c0:	4108                	lw	a0,0(a0)
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	ea0080e7          	jalr	-352(ra) # 80003862 <balloc>
    800039ca:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039ce:	06090563          	beqz	s2,80003a38 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800039d2:	0524a823          	sw	s2,80(s1)
    800039d6:	a08d                	j	80003a38 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039d8:	ff45849b          	addiw	s1,a1,-12
    800039dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039e0:	0ff00793          	li	a5,255
    800039e4:	08e7e563          	bltu	a5,a4,80003a6e <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039e8:	08052903          	lw	s2,128(a0)
    800039ec:	00091d63          	bnez	s2,80003a06 <bmap+0x72>
      addr = balloc(ip->dev);
    800039f0:	4108                	lw	a0,0(a0)
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	e70080e7          	jalr	-400(ra) # 80003862 <balloc>
    800039fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039fe:	02090d63          	beqz	s2,80003a38 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a02:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a06:	85ca                	mv	a1,s2
    80003a08:	0009a503          	lw	a0,0(s3)
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	b94080e7          	jalr	-1132(ra) # 800035a0 <bread>
    80003a14:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a16:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a1a:	02049713          	slli	a4,s1,0x20
    80003a1e:	01e75593          	srli	a1,a4,0x1e
    80003a22:	00b784b3          	add	s1,a5,a1
    80003a26:	0004a903          	lw	s2,0(s1)
    80003a2a:	02090063          	beqz	s2,80003a4a <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a2e:	8552                	mv	a0,s4
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	ca0080e7          	jalr	-864(ra) # 800036d0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a38:	854a                	mv	a0,s2
    80003a3a:	70a2                	ld	ra,40(sp)
    80003a3c:	7402                	ld	s0,32(sp)
    80003a3e:	64e2                	ld	s1,24(sp)
    80003a40:	6942                	ld	s2,16(sp)
    80003a42:	69a2                	ld	s3,8(sp)
    80003a44:	6a02                	ld	s4,0(sp)
    80003a46:	6145                	addi	sp,sp,48
    80003a48:	8082                	ret
      addr = balloc(ip->dev);
    80003a4a:	0009a503          	lw	a0,0(s3)
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	e14080e7          	jalr	-492(ra) # 80003862 <balloc>
    80003a56:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a5a:	fc090ae3          	beqz	s2,80003a2e <bmap+0x9a>
        a[bn] = addr;
    80003a5e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a62:	8552                	mv	a0,s4
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	ef6080e7          	jalr	-266(ra) # 8000495a <log_write>
    80003a6c:	b7c9                	j	80003a2e <bmap+0x9a>
  panic("bmap: out of range");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	e2a50513          	addi	a0,a0,-470 # 80008898 <syscallnames+0x228>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	aca080e7          	jalr	-1334(ra) # 80000540 <panic>

0000000080003a7e <iget>:
{
    80003a7e:	7179                	addi	sp,sp,-48
    80003a80:	f406                	sd	ra,40(sp)
    80003a82:	f022                	sd	s0,32(sp)
    80003a84:	ec26                	sd	s1,24(sp)
    80003a86:	e84a                	sd	s2,16(sp)
    80003a88:	e44e                	sd	s3,8(sp)
    80003a8a:	e052                	sd	s4,0(sp)
    80003a8c:	1800                	addi	s0,sp,48
    80003a8e:	89aa                	mv	s3,a0
    80003a90:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a92:	0023c517          	auipc	a0,0x23c
    80003a96:	71650513          	addi	a0,a0,1814 # 802401a8 <itable>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	2e8080e7          	jalr	744(ra) # 80000d82 <acquire>
  empty = 0;
    80003aa2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aa4:	0023c497          	auipc	s1,0x23c
    80003aa8:	71c48493          	addi	s1,s1,1820 # 802401c0 <itable+0x18>
    80003aac:	0023e697          	auipc	a3,0x23e
    80003ab0:	1a468693          	addi	a3,a3,420 # 80241c50 <log>
    80003ab4:	a039                	j	80003ac2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ab6:	02090b63          	beqz	s2,80003aec <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aba:	08848493          	addi	s1,s1,136
    80003abe:	02d48a63          	beq	s1,a3,80003af2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ac2:	449c                	lw	a5,8(s1)
    80003ac4:	fef059e3          	blez	a5,80003ab6 <iget+0x38>
    80003ac8:	4098                	lw	a4,0(s1)
    80003aca:	ff3716e3          	bne	a4,s3,80003ab6 <iget+0x38>
    80003ace:	40d8                	lw	a4,4(s1)
    80003ad0:	ff4713e3          	bne	a4,s4,80003ab6 <iget+0x38>
      ip->ref++;
    80003ad4:	2785                	addiw	a5,a5,1
    80003ad6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ad8:	0023c517          	auipc	a0,0x23c
    80003adc:	6d050513          	addi	a0,a0,1744 # 802401a8 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	356080e7          	jalr	854(ra) # 80000e36 <release>
      return ip;
    80003ae8:	8926                	mv	s2,s1
    80003aea:	a03d                	j	80003b18 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aec:	f7f9                	bnez	a5,80003aba <iget+0x3c>
    80003aee:	8926                	mv	s2,s1
    80003af0:	b7e9                	j	80003aba <iget+0x3c>
  if(empty == 0)
    80003af2:	02090c63          	beqz	s2,80003b2a <iget+0xac>
  ip->dev = dev;
    80003af6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003afa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003afe:	4785                	li	a5,1
    80003b00:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b04:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b08:	0023c517          	auipc	a0,0x23c
    80003b0c:	6a050513          	addi	a0,a0,1696 # 802401a8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	326080e7          	jalr	806(ra) # 80000e36 <release>
}
    80003b18:	854a                	mv	a0,s2
    80003b1a:	70a2                	ld	ra,40(sp)
    80003b1c:	7402                	ld	s0,32(sp)
    80003b1e:	64e2                	ld	s1,24(sp)
    80003b20:	6942                	ld	s2,16(sp)
    80003b22:	69a2                	ld	s3,8(sp)
    80003b24:	6a02                	ld	s4,0(sp)
    80003b26:	6145                	addi	sp,sp,48
    80003b28:	8082                	ret
    panic("iget: no inodes");
    80003b2a:	00005517          	auipc	a0,0x5
    80003b2e:	d8650513          	addi	a0,a0,-634 # 800088b0 <syscallnames+0x240>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	a0e080e7          	jalr	-1522(ra) # 80000540 <panic>

0000000080003b3a <fsinit>:
fsinit(int dev) {
    80003b3a:	7179                	addi	sp,sp,-48
    80003b3c:	f406                	sd	ra,40(sp)
    80003b3e:	f022                	sd	s0,32(sp)
    80003b40:	ec26                	sd	s1,24(sp)
    80003b42:	e84a                	sd	s2,16(sp)
    80003b44:	e44e                	sd	s3,8(sp)
    80003b46:	1800                	addi	s0,sp,48
    80003b48:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b4a:	4585                	li	a1,1
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	a54080e7          	jalr	-1452(ra) # 800035a0 <bread>
    80003b54:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b56:	0023c997          	auipc	s3,0x23c
    80003b5a:	63298993          	addi	s3,s3,1586 # 80240188 <sb>
    80003b5e:	02000613          	li	a2,32
    80003b62:	05850593          	addi	a1,a0,88
    80003b66:	854e                	mv	a0,s3
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	372080e7          	jalr	882(ra) # 80000eda <memmove>
  brelse(bp);
    80003b70:	8526                	mv	a0,s1
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	b5e080e7          	jalr	-1186(ra) # 800036d0 <brelse>
  if(sb.magic != FSMAGIC)
    80003b7a:	0009a703          	lw	a4,0(s3)
    80003b7e:	102037b7          	lui	a5,0x10203
    80003b82:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b86:	02f71263          	bne	a4,a5,80003baa <fsinit+0x70>
  initlog(dev, &sb);
    80003b8a:	0023c597          	auipc	a1,0x23c
    80003b8e:	5fe58593          	addi	a1,a1,1534 # 80240188 <sb>
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	b4a080e7          	jalr	-1206(ra) # 800046de <initlog>
}
    80003b9c:	70a2                	ld	ra,40(sp)
    80003b9e:	7402                	ld	s0,32(sp)
    80003ba0:	64e2                	ld	s1,24(sp)
    80003ba2:	6942                	ld	s2,16(sp)
    80003ba4:	69a2                	ld	s3,8(sp)
    80003ba6:	6145                	addi	sp,sp,48
    80003ba8:	8082                	ret
    panic("invalid file system");
    80003baa:	00005517          	auipc	a0,0x5
    80003bae:	d1650513          	addi	a0,a0,-746 # 800088c0 <syscallnames+0x250>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	98e080e7          	jalr	-1650(ra) # 80000540 <panic>

0000000080003bba <iinit>:
{
    80003bba:	7179                	addi	sp,sp,-48
    80003bbc:	f406                	sd	ra,40(sp)
    80003bbe:	f022                	sd	s0,32(sp)
    80003bc0:	ec26                	sd	s1,24(sp)
    80003bc2:	e84a                	sd	s2,16(sp)
    80003bc4:	e44e                	sd	s3,8(sp)
    80003bc6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bc8:	00005597          	auipc	a1,0x5
    80003bcc:	d1058593          	addi	a1,a1,-752 # 800088d8 <syscallnames+0x268>
    80003bd0:	0023c517          	auipc	a0,0x23c
    80003bd4:	5d850513          	addi	a0,a0,1496 # 802401a8 <itable>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	11a080e7          	jalr	282(ra) # 80000cf2 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003be0:	0023c497          	auipc	s1,0x23c
    80003be4:	5f048493          	addi	s1,s1,1520 # 802401d0 <itable+0x28>
    80003be8:	0023e997          	auipc	s3,0x23e
    80003bec:	07898993          	addi	s3,s3,120 # 80241c60 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bf0:	00005917          	auipc	s2,0x5
    80003bf4:	cf090913          	addi	s2,s2,-784 # 800088e0 <syscallnames+0x270>
    80003bf8:	85ca                	mv	a1,s2
    80003bfa:	8526                	mv	a0,s1
    80003bfc:	00001097          	auipc	ra,0x1
    80003c00:	e42080e7          	jalr	-446(ra) # 80004a3e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c04:	08848493          	addi	s1,s1,136
    80003c08:	ff3498e3          	bne	s1,s3,80003bf8 <iinit+0x3e>
}
    80003c0c:	70a2                	ld	ra,40(sp)
    80003c0e:	7402                	ld	s0,32(sp)
    80003c10:	64e2                	ld	s1,24(sp)
    80003c12:	6942                	ld	s2,16(sp)
    80003c14:	69a2                	ld	s3,8(sp)
    80003c16:	6145                	addi	sp,sp,48
    80003c18:	8082                	ret

0000000080003c1a <ialloc>:
{
    80003c1a:	715d                	addi	sp,sp,-80
    80003c1c:	e486                	sd	ra,72(sp)
    80003c1e:	e0a2                	sd	s0,64(sp)
    80003c20:	fc26                	sd	s1,56(sp)
    80003c22:	f84a                	sd	s2,48(sp)
    80003c24:	f44e                	sd	s3,40(sp)
    80003c26:	f052                	sd	s4,32(sp)
    80003c28:	ec56                	sd	s5,24(sp)
    80003c2a:	e85a                	sd	s6,16(sp)
    80003c2c:	e45e                	sd	s7,8(sp)
    80003c2e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c30:	0023c717          	auipc	a4,0x23c
    80003c34:	56472703          	lw	a4,1380(a4) # 80240194 <sb+0xc>
    80003c38:	4785                	li	a5,1
    80003c3a:	04e7fa63          	bgeu	a5,a4,80003c8e <ialloc+0x74>
    80003c3e:	8aaa                	mv	s5,a0
    80003c40:	8bae                	mv	s7,a1
    80003c42:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c44:	0023ca17          	auipc	s4,0x23c
    80003c48:	544a0a13          	addi	s4,s4,1348 # 80240188 <sb>
    80003c4c:	00048b1b          	sext.w	s6,s1
    80003c50:	0044d593          	srli	a1,s1,0x4
    80003c54:	018a2783          	lw	a5,24(s4)
    80003c58:	9dbd                	addw	a1,a1,a5
    80003c5a:	8556                	mv	a0,s5
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	944080e7          	jalr	-1724(ra) # 800035a0 <bread>
    80003c64:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c66:	05850993          	addi	s3,a0,88
    80003c6a:	00f4f793          	andi	a5,s1,15
    80003c6e:	079a                	slli	a5,a5,0x6
    80003c70:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c72:	00099783          	lh	a5,0(s3)
    80003c76:	c3a1                	beqz	a5,80003cb6 <ialloc+0x9c>
    brelse(bp);
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	a58080e7          	jalr	-1448(ra) # 800036d0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c80:	0485                	addi	s1,s1,1
    80003c82:	00ca2703          	lw	a4,12(s4)
    80003c86:	0004879b          	sext.w	a5,s1
    80003c8a:	fce7e1e3          	bltu	a5,a4,80003c4c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	c5a50513          	addi	a0,a0,-934 # 800088e8 <syscallnames+0x278>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	8f4080e7          	jalr	-1804(ra) # 8000058a <printf>
  return 0;
    80003c9e:	4501                	li	a0,0
}
    80003ca0:	60a6                	ld	ra,72(sp)
    80003ca2:	6406                	ld	s0,64(sp)
    80003ca4:	74e2                	ld	s1,56(sp)
    80003ca6:	7942                	ld	s2,48(sp)
    80003ca8:	79a2                	ld	s3,40(sp)
    80003caa:	7a02                	ld	s4,32(sp)
    80003cac:	6ae2                	ld	s5,24(sp)
    80003cae:	6b42                	ld	s6,16(sp)
    80003cb0:	6ba2                	ld	s7,8(sp)
    80003cb2:	6161                	addi	sp,sp,80
    80003cb4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003cb6:	04000613          	li	a2,64
    80003cba:	4581                	li	a1,0
    80003cbc:	854e                	mv	a0,s3
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	1c0080e7          	jalr	448(ra) # 80000e7e <memset>
      dip->type = type;
    80003cc6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	c8e080e7          	jalr	-882(ra) # 8000495a <log_write>
      brelse(bp);
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	9fa080e7          	jalr	-1542(ra) # 800036d0 <brelse>
      return iget(dev, inum);
    80003cde:	85da                	mv	a1,s6
    80003ce0:	8556                	mv	a0,s5
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	d9c080e7          	jalr	-612(ra) # 80003a7e <iget>
    80003cea:	bf5d                	j	80003ca0 <ialloc+0x86>

0000000080003cec <iupdate>:
{
    80003cec:	1101                	addi	sp,sp,-32
    80003cee:	ec06                	sd	ra,24(sp)
    80003cf0:	e822                	sd	s0,16(sp)
    80003cf2:	e426                	sd	s1,8(sp)
    80003cf4:	e04a                	sd	s2,0(sp)
    80003cf6:	1000                	addi	s0,sp,32
    80003cf8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cfa:	415c                	lw	a5,4(a0)
    80003cfc:	0047d79b          	srliw	a5,a5,0x4
    80003d00:	0023c597          	auipc	a1,0x23c
    80003d04:	4a05a583          	lw	a1,1184(a1) # 802401a0 <sb+0x18>
    80003d08:	9dbd                	addw	a1,a1,a5
    80003d0a:	4108                	lw	a0,0(a0)
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	894080e7          	jalr	-1900(ra) # 800035a0 <bread>
    80003d14:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d16:	05850793          	addi	a5,a0,88
    80003d1a:	40d8                	lw	a4,4(s1)
    80003d1c:	8b3d                	andi	a4,a4,15
    80003d1e:	071a                	slli	a4,a4,0x6
    80003d20:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d22:	04449703          	lh	a4,68(s1)
    80003d26:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d2a:	04649703          	lh	a4,70(s1)
    80003d2e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d32:	04849703          	lh	a4,72(s1)
    80003d36:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d3a:	04a49703          	lh	a4,74(s1)
    80003d3e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d42:	44f8                	lw	a4,76(s1)
    80003d44:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d46:	03400613          	li	a2,52
    80003d4a:	05048593          	addi	a1,s1,80
    80003d4e:	00c78513          	addi	a0,a5,12
    80003d52:	ffffd097          	auipc	ra,0xffffd
    80003d56:	188080e7          	jalr	392(ra) # 80000eda <memmove>
  log_write(bp);
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00001097          	auipc	ra,0x1
    80003d60:	bfe080e7          	jalr	-1026(ra) # 8000495a <log_write>
  brelse(bp);
    80003d64:	854a                	mv	a0,s2
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	96a080e7          	jalr	-1686(ra) # 800036d0 <brelse>
}
    80003d6e:	60e2                	ld	ra,24(sp)
    80003d70:	6442                	ld	s0,16(sp)
    80003d72:	64a2                	ld	s1,8(sp)
    80003d74:	6902                	ld	s2,0(sp)
    80003d76:	6105                	addi	sp,sp,32
    80003d78:	8082                	ret

0000000080003d7a <idup>:
{
    80003d7a:	1101                	addi	sp,sp,-32
    80003d7c:	ec06                	sd	ra,24(sp)
    80003d7e:	e822                	sd	s0,16(sp)
    80003d80:	e426                	sd	s1,8(sp)
    80003d82:	1000                	addi	s0,sp,32
    80003d84:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d86:	0023c517          	auipc	a0,0x23c
    80003d8a:	42250513          	addi	a0,a0,1058 # 802401a8 <itable>
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	ff4080e7          	jalr	-12(ra) # 80000d82 <acquire>
  ip->ref++;
    80003d96:	449c                	lw	a5,8(s1)
    80003d98:	2785                	addiw	a5,a5,1
    80003d9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d9c:	0023c517          	auipc	a0,0x23c
    80003da0:	40c50513          	addi	a0,a0,1036 # 802401a8 <itable>
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	092080e7          	jalr	146(ra) # 80000e36 <release>
}
    80003dac:	8526                	mv	a0,s1
    80003dae:	60e2                	ld	ra,24(sp)
    80003db0:	6442                	ld	s0,16(sp)
    80003db2:	64a2                	ld	s1,8(sp)
    80003db4:	6105                	addi	sp,sp,32
    80003db6:	8082                	ret

0000000080003db8 <ilock>:
{
    80003db8:	1101                	addi	sp,sp,-32
    80003dba:	ec06                	sd	ra,24(sp)
    80003dbc:	e822                	sd	s0,16(sp)
    80003dbe:	e426                	sd	s1,8(sp)
    80003dc0:	e04a                	sd	s2,0(sp)
    80003dc2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dc4:	c115                	beqz	a0,80003de8 <ilock+0x30>
    80003dc6:	84aa                	mv	s1,a0
    80003dc8:	451c                	lw	a5,8(a0)
    80003dca:	00f05f63          	blez	a5,80003de8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dce:	0541                	addi	a0,a0,16
    80003dd0:	00001097          	auipc	ra,0x1
    80003dd4:	ca8080e7          	jalr	-856(ra) # 80004a78 <acquiresleep>
  if(ip->valid == 0){
    80003dd8:	40bc                	lw	a5,64(s1)
    80003dda:	cf99                	beqz	a5,80003df8 <ilock+0x40>
}
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	64a2                	ld	s1,8(sp)
    80003de2:	6902                	ld	s2,0(sp)
    80003de4:	6105                	addi	sp,sp,32
    80003de6:	8082                	ret
    panic("ilock");
    80003de8:	00005517          	auipc	a0,0x5
    80003dec:	b1850513          	addi	a0,a0,-1256 # 80008900 <syscallnames+0x290>
    80003df0:	ffffc097          	auipc	ra,0xffffc
    80003df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003df8:	40dc                	lw	a5,4(s1)
    80003dfa:	0047d79b          	srliw	a5,a5,0x4
    80003dfe:	0023c597          	auipc	a1,0x23c
    80003e02:	3a25a583          	lw	a1,930(a1) # 802401a0 <sb+0x18>
    80003e06:	9dbd                	addw	a1,a1,a5
    80003e08:	4088                	lw	a0,0(s1)
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	796080e7          	jalr	1942(ra) # 800035a0 <bread>
    80003e12:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e14:	05850593          	addi	a1,a0,88
    80003e18:	40dc                	lw	a5,4(s1)
    80003e1a:	8bbd                	andi	a5,a5,15
    80003e1c:	079a                	slli	a5,a5,0x6
    80003e1e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e20:	00059783          	lh	a5,0(a1)
    80003e24:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e28:	00259783          	lh	a5,2(a1)
    80003e2c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e30:	00459783          	lh	a5,4(a1)
    80003e34:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e38:	00659783          	lh	a5,6(a1)
    80003e3c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e40:	459c                	lw	a5,8(a1)
    80003e42:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e44:	03400613          	li	a2,52
    80003e48:	05b1                	addi	a1,a1,12
    80003e4a:	05048513          	addi	a0,s1,80
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	08c080e7          	jalr	140(ra) # 80000eda <memmove>
    brelse(bp);
    80003e56:	854a                	mv	a0,s2
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	878080e7          	jalr	-1928(ra) # 800036d0 <brelse>
    ip->valid = 1;
    80003e60:	4785                	li	a5,1
    80003e62:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e64:	04449783          	lh	a5,68(s1)
    80003e68:	fbb5                	bnez	a5,80003ddc <ilock+0x24>
      panic("ilock: no type");
    80003e6a:	00005517          	auipc	a0,0x5
    80003e6e:	a9e50513          	addi	a0,a0,-1378 # 80008908 <syscallnames+0x298>
    80003e72:	ffffc097          	auipc	ra,0xffffc
    80003e76:	6ce080e7          	jalr	1742(ra) # 80000540 <panic>

0000000080003e7a <iunlock>:
{
    80003e7a:	1101                	addi	sp,sp,-32
    80003e7c:	ec06                	sd	ra,24(sp)
    80003e7e:	e822                	sd	s0,16(sp)
    80003e80:	e426                	sd	s1,8(sp)
    80003e82:	e04a                	sd	s2,0(sp)
    80003e84:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e86:	c905                	beqz	a0,80003eb6 <iunlock+0x3c>
    80003e88:	84aa                	mv	s1,a0
    80003e8a:	01050913          	addi	s2,a0,16
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00001097          	auipc	ra,0x1
    80003e94:	c82080e7          	jalr	-894(ra) # 80004b12 <holdingsleep>
    80003e98:	cd19                	beqz	a0,80003eb6 <iunlock+0x3c>
    80003e9a:	449c                	lw	a5,8(s1)
    80003e9c:	00f05d63          	blez	a5,80003eb6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	00001097          	auipc	ra,0x1
    80003ea6:	c2c080e7          	jalr	-980(ra) # 80004ace <releasesleep>
}
    80003eaa:	60e2                	ld	ra,24(sp)
    80003eac:	6442                	ld	s0,16(sp)
    80003eae:	64a2                	ld	s1,8(sp)
    80003eb0:	6902                	ld	s2,0(sp)
    80003eb2:	6105                	addi	sp,sp,32
    80003eb4:	8082                	ret
    panic("iunlock");
    80003eb6:	00005517          	auipc	a0,0x5
    80003eba:	a6250513          	addi	a0,a0,-1438 # 80008918 <syscallnames+0x2a8>
    80003ebe:	ffffc097          	auipc	ra,0xffffc
    80003ec2:	682080e7          	jalr	1666(ra) # 80000540 <panic>

0000000080003ec6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ec6:	7179                	addi	sp,sp,-48
    80003ec8:	f406                	sd	ra,40(sp)
    80003eca:	f022                	sd	s0,32(sp)
    80003ecc:	ec26                	sd	s1,24(sp)
    80003ece:	e84a                	sd	s2,16(sp)
    80003ed0:	e44e                	sd	s3,8(sp)
    80003ed2:	e052                	sd	s4,0(sp)
    80003ed4:	1800                	addi	s0,sp,48
    80003ed6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ed8:	05050493          	addi	s1,a0,80
    80003edc:	08050913          	addi	s2,a0,128
    80003ee0:	a021                	j	80003ee8 <itrunc+0x22>
    80003ee2:	0491                	addi	s1,s1,4
    80003ee4:	01248d63          	beq	s1,s2,80003efe <itrunc+0x38>
    if(ip->addrs[i]){
    80003ee8:	408c                	lw	a1,0(s1)
    80003eea:	dde5                	beqz	a1,80003ee2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003eec:	0009a503          	lw	a0,0(s3)
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	8f6080e7          	jalr	-1802(ra) # 800037e6 <bfree>
      ip->addrs[i] = 0;
    80003ef8:	0004a023          	sw	zero,0(s1)
    80003efc:	b7dd                	j	80003ee2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003efe:	0809a583          	lw	a1,128(s3)
    80003f02:	e185                	bnez	a1,80003f22 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f04:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f08:	854e                	mv	a0,s3
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	de2080e7          	jalr	-542(ra) # 80003cec <iupdate>
}
    80003f12:	70a2                	ld	ra,40(sp)
    80003f14:	7402                	ld	s0,32(sp)
    80003f16:	64e2                	ld	s1,24(sp)
    80003f18:	6942                	ld	s2,16(sp)
    80003f1a:	69a2                	ld	s3,8(sp)
    80003f1c:	6a02                	ld	s4,0(sp)
    80003f1e:	6145                	addi	sp,sp,48
    80003f20:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f22:	0009a503          	lw	a0,0(s3)
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	67a080e7          	jalr	1658(ra) # 800035a0 <bread>
    80003f2e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f30:	05850493          	addi	s1,a0,88
    80003f34:	45850913          	addi	s2,a0,1112
    80003f38:	a021                	j	80003f40 <itrunc+0x7a>
    80003f3a:	0491                	addi	s1,s1,4
    80003f3c:	01248b63          	beq	s1,s2,80003f52 <itrunc+0x8c>
      if(a[j])
    80003f40:	408c                	lw	a1,0(s1)
    80003f42:	dde5                	beqz	a1,80003f3a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f44:	0009a503          	lw	a0,0(s3)
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	89e080e7          	jalr	-1890(ra) # 800037e6 <bfree>
    80003f50:	b7ed                	j	80003f3a <itrunc+0x74>
    brelse(bp);
    80003f52:	8552                	mv	a0,s4
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	77c080e7          	jalr	1916(ra) # 800036d0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f5c:	0809a583          	lw	a1,128(s3)
    80003f60:	0009a503          	lw	a0,0(s3)
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	882080e7          	jalr	-1918(ra) # 800037e6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f6c:	0809a023          	sw	zero,128(s3)
    80003f70:	bf51                	j	80003f04 <itrunc+0x3e>

0000000080003f72 <iput>:
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	e426                	sd	s1,8(sp)
    80003f7a:	e04a                	sd	s2,0(sp)
    80003f7c:	1000                	addi	s0,sp,32
    80003f7e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f80:	0023c517          	auipc	a0,0x23c
    80003f84:	22850513          	addi	a0,a0,552 # 802401a8 <itable>
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	dfa080e7          	jalr	-518(ra) # 80000d82 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f90:	4498                	lw	a4,8(s1)
    80003f92:	4785                	li	a5,1
    80003f94:	02f70363          	beq	a4,a5,80003fba <iput+0x48>
  ip->ref--;
    80003f98:	449c                	lw	a5,8(s1)
    80003f9a:	37fd                	addiw	a5,a5,-1
    80003f9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f9e:	0023c517          	auipc	a0,0x23c
    80003fa2:	20a50513          	addi	a0,a0,522 # 802401a8 <itable>
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	e90080e7          	jalr	-368(ra) # 80000e36 <release>
}
    80003fae:	60e2                	ld	ra,24(sp)
    80003fb0:	6442                	ld	s0,16(sp)
    80003fb2:	64a2                	ld	s1,8(sp)
    80003fb4:	6902                	ld	s2,0(sp)
    80003fb6:	6105                	addi	sp,sp,32
    80003fb8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fba:	40bc                	lw	a5,64(s1)
    80003fbc:	dff1                	beqz	a5,80003f98 <iput+0x26>
    80003fbe:	04a49783          	lh	a5,74(s1)
    80003fc2:	fbf9                	bnez	a5,80003f98 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fc4:	01048913          	addi	s2,s1,16
    80003fc8:	854a                	mv	a0,s2
    80003fca:	00001097          	auipc	ra,0x1
    80003fce:	aae080e7          	jalr	-1362(ra) # 80004a78 <acquiresleep>
    release(&itable.lock);
    80003fd2:	0023c517          	auipc	a0,0x23c
    80003fd6:	1d650513          	addi	a0,a0,470 # 802401a8 <itable>
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	e5c080e7          	jalr	-420(ra) # 80000e36 <release>
    itrunc(ip);
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	ee2080e7          	jalr	-286(ra) # 80003ec6 <itrunc>
    ip->type = 0;
    80003fec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	cfa080e7          	jalr	-774(ra) # 80003cec <iupdate>
    ip->valid = 0;
    80003ffa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ffe:	854a                	mv	a0,s2
    80004000:	00001097          	auipc	ra,0x1
    80004004:	ace080e7          	jalr	-1330(ra) # 80004ace <releasesleep>
    acquire(&itable.lock);
    80004008:	0023c517          	auipc	a0,0x23c
    8000400c:	1a050513          	addi	a0,a0,416 # 802401a8 <itable>
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	d72080e7          	jalr	-654(ra) # 80000d82 <acquire>
    80004018:	b741                	j	80003f98 <iput+0x26>

000000008000401a <iunlockput>:
{
    8000401a:	1101                	addi	sp,sp,-32
    8000401c:	ec06                	sd	ra,24(sp)
    8000401e:	e822                	sd	s0,16(sp)
    80004020:	e426                	sd	s1,8(sp)
    80004022:	1000                	addi	s0,sp,32
    80004024:	84aa                	mv	s1,a0
  iunlock(ip);
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	e54080e7          	jalr	-428(ra) # 80003e7a <iunlock>
  iput(ip);
    8000402e:	8526                	mv	a0,s1
    80004030:	00000097          	auipc	ra,0x0
    80004034:	f42080e7          	jalr	-190(ra) # 80003f72 <iput>
}
    80004038:	60e2                	ld	ra,24(sp)
    8000403a:	6442                	ld	s0,16(sp)
    8000403c:	64a2                	ld	s1,8(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret

0000000080004042 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004042:	1141                	addi	sp,sp,-16
    80004044:	e422                	sd	s0,8(sp)
    80004046:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004048:	411c                	lw	a5,0(a0)
    8000404a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000404c:	415c                	lw	a5,4(a0)
    8000404e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004050:	04451783          	lh	a5,68(a0)
    80004054:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004058:	04a51783          	lh	a5,74(a0)
    8000405c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004060:	04c56783          	lwu	a5,76(a0)
    80004064:	e99c                	sd	a5,16(a1)
}
    80004066:	6422                	ld	s0,8(sp)
    80004068:	0141                	addi	sp,sp,16
    8000406a:	8082                	ret

000000008000406c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000406c:	457c                	lw	a5,76(a0)
    8000406e:	0ed7e963          	bltu	a5,a3,80004160 <readi+0xf4>
{
    80004072:	7159                	addi	sp,sp,-112
    80004074:	f486                	sd	ra,104(sp)
    80004076:	f0a2                	sd	s0,96(sp)
    80004078:	eca6                	sd	s1,88(sp)
    8000407a:	e8ca                	sd	s2,80(sp)
    8000407c:	e4ce                	sd	s3,72(sp)
    8000407e:	e0d2                	sd	s4,64(sp)
    80004080:	fc56                	sd	s5,56(sp)
    80004082:	f85a                	sd	s6,48(sp)
    80004084:	f45e                	sd	s7,40(sp)
    80004086:	f062                	sd	s8,32(sp)
    80004088:	ec66                	sd	s9,24(sp)
    8000408a:	e86a                	sd	s10,16(sp)
    8000408c:	e46e                	sd	s11,8(sp)
    8000408e:	1880                	addi	s0,sp,112
    80004090:	8b2a                	mv	s6,a0
    80004092:	8bae                	mv	s7,a1
    80004094:	8a32                	mv	s4,a2
    80004096:	84b6                	mv	s1,a3
    80004098:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000409a:	9f35                	addw	a4,a4,a3
    return 0;
    8000409c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000409e:	0ad76063          	bltu	a4,a3,8000413e <readi+0xd2>
  if(off + n > ip->size)
    800040a2:	00e7f463          	bgeu	a5,a4,800040aa <readi+0x3e>
    n = ip->size - off;
    800040a6:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040aa:	0a0a8963          	beqz	s5,8000415c <readi+0xf0>
    800040ae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b0:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040b4:	5c7d                	li	s8,-1
    800040b6:	a82d                	j	800040f0 <readi+0x84>
    800040b8:	020d1d93          	slli	s11,s10,0x20
    800040bc:	020ddd93          	srli	s11,s11,0x20
    800040c0:	05890613          	addi	a2,s2,88
    800040c4:	86ee                	mv	a3,s11
    800040c6:	963a                	add	a2,a2,a4
    800040c8:	85d2                	mv	a1,s4
    800040ca:	855e                	mv	a0,s7
    800040cc:	ffffe097          	auipc	ra,0xffffe
    800040d0:	750080e7          	jalr	1872(ra) # 8000281c <either_copyout>
    800040d4:	05850d63          	beq	a0,s8,8000412e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040d8:	854a                	mv	a0,s2
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	5f6080e7          	jalr	1526(ra) # 800036d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040e2:	013d09bb          	addw	s3,s10,s3
    800040e6:	009d04bb          	addw	s1,s10,s1
    800040ea:	9a6e                	add	s4,s4,s11
    800040ec:	0559f763          	bgeu	s3,s5,8000413a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040f0:	00a4d59b          	srliw	a1,s1,0xa
    800040f4:	855a                	mv	a0,s6
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	89e080e7          	jalr	-1890(ra) # 80003994 <bmap>
    800040fe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004102:	cd85                	beqz	a1,8000413a <readi+0xce>
    bp = bread(ip->dev, addr);
    80004104:	000b2503          	lw	a0,0(s6)
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	498080e7          	jalr	1176(ra) # 800035a0 <bread>
    80004110:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004112:	3ff4f713          	andi	a4,s1,1023
    80004116:	40ec87bb          	subw	a5,s9,a4
    8000411a:	413a86bb          	subw	a3,s5,s3
    8000411e:	8d3e                	mv	s10,a5
    80004120:	2781                	sext.w	a5,a5
    80004122:	0006861b          	sext.w	a2,a3
    80004126:	f8f679e3          	bgeu	a2,a5,800040b8 <readi+0x4c>
    8000412a:	8d36                	mv	s10,a3
    8000412c:	b771                	j	800040b8 <readi+0x4c>
      brelse(bp);
    8000412e:	854a                	mv	a0,s2
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	5a0080e7          	jalr	1440(ra) # 800036d0 <brelse>
      tot = -1;
    80004138:	59fd                	li	s3,-1
  }
  return tot;
    8000413a:	0009851b          	sext.w	a0,s3
}
    8000413e:	70a6                	ld	ra,104(sp)
    80004140:	7406                	ld	s0,96(sp)
    80004142:	64e6                	ld	s1,88(sp)
    80004144:	6946                	ld	s2,80(sp)
    80004146:	69a6                	ld	s3,72(sp)
    80004148:	6a06                	ld	s4,64(sp)
    8000414a:	7ae2                	ld	s5,56(sp)
    8000414c:	7b42                	ld	s6,48(sp)
    8000414e:	7ba2                	ld	s7,40(sp)
    80004150:	7c02                	ld	s8,32(sp)
    80004152:	6ce2                	ld	s9,24(sp)
    80004154:	6d42                	ld	s10,16(sp)
    80004156:	6da2                	ld	s11,8(sp)
    80004158:	6165                	addi	sp,sp,112
    8000415a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000415c:	89d6                	mv	s3,s5
    8000415e:	bff1                	j	8000413a <readi+0xce>
    return 0;
    80004160:	4501                	li	a0,0
}
    80004162:	8082                	ret

0000000080004164 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004164:	457c                	lw	a5,76(a0)
    80004166:	10d7e863          	bltu	a5,a3,80004276 <writei+0x112>
{
    8000416a:	7159                	addi	sp,sp,-112
    8000416c:	f486                	sd	ra,104(sp)
    8000416e:	f0a2                	sd	s0,96(sp)
    80004170:	eca6                	sd	s1,88(sp)
    80004172:	e8ca                	sd	s2,80(sp)
    80004174:	e4ce                	sd	s3,72(sp)
    80004176:	e0d2                	sd	s4,64(sp)
    80004178:	fc56                	sd	s5,56(sp)
    8000417a:	f85a                	sd	s6,48(sp)
    8000417c:	f45e                	sd	s7,40(sp)
    8000417e:	f062                	sd	s8,32(sp)
    80004180:	ec66                	sd	s9,24(sp)
    80004182:	e86a                	sd	s10,16(sp)
    80004184:	e46e                	sd	s11,8(sp)
    80004186:	1880                	addi	s0,sp,112
    80004188:	8aaa                	mv	s5,a0
    8000418a:	8bae                	mv	s7,a1
    8000418c:	8a32                	mv	s4,a2
    8000418e:	8936                	mv	s2,a3
    80004190:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004192:	00e687bb          	addw	a5,a3,a4
    80004196:	0ed7e263          	bltu	a5,a3,8000427a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000419a:	00043737          	lui	a4,0x43
    8000419e:	0ef76063          	bltu	a4,a5,8000427e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a2:	0c0b0863          	beqz	s6,80004272 <writei+0x10e>
    800041a6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a8:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041ac:	5c7d                	li	s8,-1
    800041ae:	a091                	j	800041f2 <writei+0x8e>
    800041b0:	020d1d93          	slli	s11,s10,0x20
    800041b4:	020ddd93          	srli	s11,s11,0x20
    800041b8:	05848513          	addi	a0,s1,88
    800041bc:	86ee                	mv	a3,s11
    800041be:	8652                	mv	a2,s4
    800041c0:	85de                	mv	a1,s7
    800041c2:	953a                	add	a0,a0,a4
    800041c4:	ffffe097          	auipc	ra,0xffffe
    800041c8:	6ae080e7          	jalr	1710(ra) # 80002872 <either_copyin>
    800041cc:	07850263          	beq	a0,s8,80004230 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041d0:	8526                	mv	a0,s1
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	788080e7          	jalr	1928(ra) # 8000495a <log_write>
    brelse(bp);
    800041da:	8526                	mv	a0,s1
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	4f4080e7          	jalr	1268(ra) # 800036d0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041e4:	013d09bb          	addw	s3,s10,s3
    800041e8:	012d093b          	addw	s2,s10,s2
    800041ec:	9a6e                	add	s4,s4,s11
    800041ee:	0569f663          	bgeu	s3,s6,8000423a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041f2:	00a9559b          	srliw	a1,s2,0xa
    800041f6:	8556                	mv	a0,s5
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	79c080e7          	jalr	1948(ra) # 80003994 <bmap>
    80004200:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004204:	c99d                	beqz	a1,8000423a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004206:	000aa503          	lw	a0,0(s5)
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	396080e7          	jalr	918(ra) # 800035a0 <bread>
    80004212:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004214:	3ff97713          	andi	a4,s2,1023
    80004218:	40ec87bb          	subw	a5,s9,a4
    8000421c:	413b06bb          	subw	a3,s6,s3
    80004220:	8d3e                	mv	s10,a5
    80004222:	2781                	sext.w	a5,a5
    80004224:	0006861b          	sext.w	a2,a3
    80004228:	f8f674e3          	bgeu	a2,a5,800041b0 <writei+0x4c>
    8000422c:	8d36                	mv	s10,a3
    8000422e:	b749                	j	800041b0 <writei+0x4c>
      brelse(bp);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	49e080e7          	jalr	1182(ra) # 800036d0 <brelse>
  }

  if(off > ip->size)
    8000423a:	04caa783          	lw	a5,76(s5)
    8000423e:	0127f463          	bgeu	a5,s2,80004246 <writei+0xe2>
    ip->size = off;
    80004242:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004246:	8556                	mv	a0,s5
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	aa4080e7          	jalr	-1372(ra) # 80003cec <iupdate>

  return tot;
    80004250:	0009851b          	sext.w	a0,s3
}
    80004254:	70a6                	ld	ra,104(sp)
    80004256:	7406                	ld	s0,96(sp)
    80004258:	64e6                	ld	s1,88(sp)
    8000425a:	6946                	ld	s2,80(sp)
    8000425c:	69a6                	ld	s3,72(sp)
    8000425e:	6a06                	ld	s4,64(sp)
    80004260:	7ae2                	ld	s5,56(sp)
    80004262:	7b42                	ld	s6,48(sp)
    80004264:	7ba2                	ld	s7,40(sp)
    80004266:	7c02                	ld	s8,32(sp)
    80004268:	6ce2                	ld	s9,24(sp)
    8000426a:	6d42                	ld	s10,16(sp)
    8000426c:	6da2                	ld	s11,8(sp)
    8000426e:	6165                	addi	sp,sp,112
    80004270:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004272:	89da                	mv	s3,s6
    80004274:	bfc9                	j	80004246 <writei+0xe2>
    return -1;
    80004276:	557d                	li	a0,-1
}
    80004278:	8082                	ret
    return -1;
    8000427a:	557d                	li	a0,-1
    8000427c:	bfe1                	j	80004254 <writei+0xf0>
    return -1;
    8000427e:	557d                	li	a0,-1
    80004280:	bfd1                	j	80004254 <writei+0xf0>

0000000080004282 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004282:	1141                	addi	sp,sp,-16
    80004284:	e406                	sd	ra,8(sp)
    80004286:	e022                	sd	s0,0(sp)
    80004288:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000428a:	4639                	li	a2,14
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	cc2080e7          	jalr	-830(ra) # 80000f4e <strncmp>
}
    80004294:	60a2                	ld	ra,8(sp)
    80004296:	6402                	ld	s0,0(sp)
    80004298:	0141                	addi	sp,sp,16
    8000429a:	8082                	ret

000000008000429c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000429c:	7139                	addi	sp,sp,-64
    8000429e:	fc06                	sd	ra,56(sp)
    800042a0:	f822                	sd	s0,48(sp)
    800042a2:	f426                	sd	s1,40(sp)
    800042a4:	f04a                	sd	s2,32(sp)
    800042a6:	ec4e                	sd	s3,24(sp)
    800042a8:	e852                	sd	s4,16(sp)
    800042aa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042ac:	04451703          	lh	a4,68(a0)
    800042b0:	4785                	li	a5,1
    800042b2:	00f71a63          	bne	a4,a5,800042c6 <dirlookup+0x2a>
    800042b6:	892a                	mv	s2,a0
    800042b8:	89ae                	mv	s3,a1
    800042ba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042bc:	457c                	lw	a5,76(a0)
    800042be:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042c0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c2:	e79d                	bnez	a5,800042f0 <dirlookup+0x54>
    800042c4:	a8a5                	j	8000433c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042c6:	00004517          	auipc	a0,0x4
    800042ca:	65a50513          	addi	a0,a0,1626 # 80008920 <syscallnames+0x2b0>
    800042ce:	ffffc097          	auipc	ra,0xffffc
    800042d2:	272080e7          	jalr	626(ra) # 80000540 <panic>
      panic("dirlookup read");
    800042d6:	00004517          	auipc	a0,0x4
    800042da:	66250513          	addi	a0,a0,1634 # 80008938 <syscallnames+0x2c8>
    800042de:	ffffc097          	auipc	ra,0xffffc
    800042e2:	262080e7          	jalr	610(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e6:	24c1                	addiw	s1,s1,16
    800042e8:	04c92783          	lw	a5,76(s2)
    800042ec:	04f4f763          	bgeu	s1,a5,8000433a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f0:	4741                	li	a4,16
    800042f2:	86a6                	mv	a3,s1
    800042f4:	fc040613          	addi	a2,s0,-64
    800042f8:	4581                	li	a1,0
    800042fa:	854a                	mv	a0,s2
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	d70080e7          	jalr	-656(ra) # 8000406c <readi>
    80004304:	47c1                	li	a5,16
    80004306:	fcf518e3          	bne	a0,a5,800042d6 <dirlookup+0x3a>
    if(de.inum == 0)
    8000430a:	fc045783          	lhu	a5,-64(s0)
    8000430e:	dfe1                	beqz	a5,800042e6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004310:	fc240593          	addi	a1,s0,-62
    80004314:	854e                	mv	a0,s3
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	f6c080e7          	jalr	-148(ra) # 80004282 <namecmp>
    8000431e:	f561                	bnez	a0,800042e6 <dirlookup+0x4a>
      if(poff)
    80004320:	000a0463          	beqz	s4,80004328 <dirlookup+0x8c>
        *poff = off;
    80004324:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004328:	fc045583          	lhu	a1,-64(s0)
    8000432c:	00092503          	lw	a0,0(s2)
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	74e080e7          	jalr	1870(ra) # 80003a7e <iget>
    80004338:	a011                	j	8000433c <dirlookup+0xa0>
  return 0;
    8000433a:	4501                	li	a0,0
}
    8000433c:	70e2                	ld	ra,56(sp)
    8000433e:	7442                	ld	s0,48(sp)
    80004340:	74a2                	ld	s1,40(sp)
    80004342:	7902                	ld	s2,32(sp)
    80004344:	69e2                	ld	s3,24(sp)
    80004346:	6a42                	ld	s4,16(sp)
    80004348:	6121                	addi	sp,sp,64
    8000434a:	8082                	ret

000000008000434c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000434c:	711d                	addi	sp,sp,-96
    8000434e:	ec86                	sd	ra,88(sp)
    80004350:	e8a2                	sd	s0,80(sp)
    80004352:	e4a6                	sd	s1,72(sp)
    80004354:	e0ca                	sd	s2,64(sp)
    80004356:	fc4e                	sd	s3,56(sp)
    80004358:	f852                	sd	s4,48(sp)
    8000435a:	f456                	sd	s5,40(sp)
    8000435c:	f05a                	sd	s6,32(sp)
    8000435e:	ec5e                	sd	s7,24(sp)
    80004360:	e862                	sd	s8,16(sp)
    80004362:	e466                	sd	s9,8(sp)
    80004364:	e06a                	sd	s10,0(sp)
    80004366:	1080                	addi	s0,sp,96
    80004368:	84aa                	mv	s1,a0
    8000436a:	8b2e                	mv	s6,a1
    8000436c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000436e:	00054703          	lbu	a4,0(a0)
    80004372:	02f00793          	li	a5,47
    80004376:	02f70363          	beq	a4,a5,8000439c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000437a:	ffffe097          	auipc	ra,0xffffe
    8000437e:	808080e7          	jalr	-2040(ra) # 80001b82 <myproc>
    80004382:	15053503          	ld	a0,336(a0)
    80004386:	00000097          	auipc	ra,0x0
    8000438a:	9f4080e7          	jalr	-1548(ra) # 80003d7a <idup>
    8000438e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004390:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004394:	4cb5                	li	s9,13
  len = path - s;
    80004396:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004398:	4c05                	li	s8,1
    8000439a:	a87d                	j	80004458 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000439c:	4585                	li	a1,1
    8000439e:	4505                	li	a0,1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	6de080e7          	jalr	1758(ra) # 80003a7e <iget>
    800043a8:	8a2a                	mv	s4,a0
    800043aa:	b7dd                	j	80004390 <namex+0x44>
      iunlockput(ip);
    800043ac:	8552                	mv	a0,s4
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	c6c080e7          	jalr	-916(ra) # 8000401a <iunlockput>
      return 0;
    800043b6:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043b8:	8552                	mv	a0,s4
    800043ba:	60e6                	ld	ra,88(sp)
    800043bc:	6446                	ld	s0,80(sp)
    800043be:	64a6                	ld	s1,72(sp)
    800043c0:	6906                	ld	s2,64(sp)
    800043c2:	79e2                	ld	s3,56(sp)
    800043c4:	7a42                	ld	s4,48(sp)
    800043c6:	7aa2                	ld	s5,40(sp)
    800043c8:	7b02                	ld	s6,32(sp)
    800043ca:	6be2                	ld	s7,24(sp)
    800043cc:	6c42                	ld	s8,16(sp)
    800043ce:	6ca2                	ld	s9,8(sp)
    800043d0:	6d02                	ld	s10,0(sp)
    800043d2:	6125                	addi	sp,sp,96
    800043d4:	8082                	ret
      iunlock(ip);
    800043d6:	8552                	mv	a0,s4
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	aa2080e7          	jalr	-1374(ra) # 80003e7a <iunlock>
      return ip;
    800043e0:	bfe1                	j	800043b8 <namex+0x6c>
      iunlockput(ip);
    800043e2:	8552                	mv	a0,s4
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	c36080e7          	jalr	-970(ra) # 8000401a <iunlockput>
      return 0;
    800043ec:	8a4e                	mv	s4,s3
    800043ee:	b7e9                	j	800043b8 <namex+0x6c>
  len = path - s;
    800043f0:	40998633          	sub	a2,s3,s1
    800043f4:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800043f8:	09acd863          	bge	s9,s10,80004488 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800043fc:	4639                	li	a2,14
    800043fe:	85a6                	mv	a1,s1
    80004400:	8556                	mv	a0,s5
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	ad8080e7          	jalr	-1320(ra) # 80000eda <memmove>
    8000440a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000440c:	0004c783          	lbu	a5,0(s1)
    80004410:	01279763          	bne	a5,s2,8000441e <namex+0xd2>
    path++;
    80004414:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004416:	0004c783          	lbu	a5,0(s1)
    8000441a:	ff278de3          	beq	a5,s2,80004414 <namex+0xc8>
    ilock(ip);
    8000441e:	8552                	mv	a0,s4
    80004420:	00000097          	auipc	ra,0x0
    80004424:	998080e7          	jalr	-1640(ra) # 80003db8 <ilock>
    if(ip->type != T_DIR){
    80004428:	044a1783          	lh	a5,68(s4)
    8000442c:	f98790e3          	bne	a5,s8,800043ac <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004430:	000b0563          	beqz	s6,8000443a <namex+0xee>
    80004434:	0004c783          	lbu	a5,0(s1)
    80004438:	dfd9                	beqz	a5,800043d6 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000443a:	865e                	mv	a2,s7
    8000443c:	85d6                	mv	a1,s5
    8000443e:	8552                	mv	a0,s4
    80004440:	00000097          	auipc	ra,0x0
    80004444:	e5c080e7          	jalr	-420(ra) # 8000429c <dirlookup>
    80004448:	89aa                	mv	s3,a0
    8000444a:	dd41                	beqz	a0,800043e2 <namex+0x96>
    iunlockput(ip);
    8000444c:	8552                	mv	a0,s4
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	bcc080e7          	jalr	-1076(ra) # 8000401a <iunlockput>
    ip = next;
    80004456:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004458:	0004c783          	lbu	a5,0(s1)
    8000445c:	01279763          	bne	a5,s2,8000446a <namex+0x11e>
    path++;
    80004460:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004462:	0004c783          	lbu	a5,0(s1)
    80004466:	ff278de3          	beq	a5,s2,80004460 <namex+0x114>
  if(*path == 0)
    8000446a:	cb9d                	beqz	a5,800044a0 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000446c:	0004c783          	lbu	a5,0(s1)
    80004470:	89a6                	mv	s3,s1
  len = path - s;
    80004472:	8d5e                	mv	s10,s7
    80004474:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004476:	01278963          	beq	a5,s2,80004488 <namex+0x13c>
    8000447a:	dbbd                	beqz	a5,800043f0 <namex+0xa4>
    path++;
    8000447c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000447e:	0009c783          	lbu	a5,0(s3)
    80004482:	ff279ce3          	bne	a5,s2,8000447a <namex+0x12e>
    80004486:	b7ad                	j	800043f0 <namex+0xa4>
    memmove(name, s, len);
    80004488:	2601                	sext.w	a2,a2
    8000448a:	85a6                	mv	a1,s1
    8000448c:	8556                	mv	a0,s5
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	a4c080e7          	jalr	-1460(ra) # 80000eda <memmove>
    name[len] = 0;
    80004496:	9d56                	add	s10,s10,s5
    80004498:	000d0023          	sb	zero,0(s10)
    8000449c:	84ce                	mv	s1,s3
    8000449e:	b7bd                	j	8000440c <namex+0xc0>
  if(nameiparent){
    800044a0:	f00b0ce3          	beqz	s6,800043b8 <namex+0x6c>
    iput(ip);
    800044a4:	8552                	mv	a0,s4
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	acc080e7          	jalr	-1332(ra) # 80003f72 <iput>
    return 0;
    800044ae:	4a01                	li	s4,0
    800044b0:	b721                	j	800043b8 <namex+0x6c>

00000000800044b2 <dirlink>:
{
    800044b2:	7139                	addi	sp,sp,-64
    800044b4:	fc06                	sd	ra,56(sp)
    800044b6:	f822                	sd	s0,48(sp)
    800044b8:	f426                	sd	s1,40(sp)
    800044ba:	f04a                	sd	s2,32(sp)
    800044bc:	ec4e                	sd	s3,24(sp)
    800044be:	e852                	sd	s4,16(sp)
    800044c0:	0080                	addi	s0,sp,64
    800044c2:	892a                	mv	s2,a0
    800044c4:	8a2e                	mv	s4,a1
    800044c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044c8:	4601                	li	a2,0
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	dd2080e7          	jalr	-558(ra) # 8000429c <dirlookup>
    800044d2:	e93d                	bnez	a0,80004548 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d4:	04c92483          	lw	s1,76(s2)
    800044d8:	c49d                	beqz	s1,80004506 <dirlink+0x54>
    800044da:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044dc:	4741                	li	a4,16
    800044de:	86a6                	mv	a3,s1
    800044e0:	fc040613          	addi	a2,s0,-64
    800044e4:	4581                	li	a1,0
    800044e6:	854a                	mv	a0,s2
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	b84080e7          	jalr	-1148(ra) # 8000406c <readi>
    800044f0:	47c1                	li	a5,16
    800044f2:	06f51163          	bne	a0,a5,80004554 <dirlink+0xa2>
    if(de.inum == 0)
    800044f6:	fc045783          	lhu	a5,-64(s0)
    800044fa:	c791                	beqz	a5,80004506 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044fc:	24c1                	addiw	s1,s1,16
    800044fe:	04c92783          	lw	a5,76(s2)
    80004502:	fcf4ede3          	bltu	s1,a5,800044dc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004506:	4639                	li	a2,14
    80004508:	85d2                	mv	a1,s4
    8000450a:	fc240513          	addi	a0,s0,-62
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	a7c080e7          	jalr	-1412(ra) # 80000f8a <strncpy>
  de.inum = inum;
    80004516:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000451a:	4741                	li	a4,16
    8000451c:	86a6                	mv	a3,s1
    8000451e:	fc040613          	addi	a2,s0,-64
    80004522:	4581                	li	a1,0
    80004524:	854a                	mv	a0,s2
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	c3e080e7          	jalr	-962(ra) # 80004164 <writei>
    8000452e:	1541                	addi	a0,a0,-16
    80004530:	00a03533          	snez	a0,a0
    80004534:	40a00533          	neg	a0,a0
}
    80004538:	70e2                	ld	ra,56(sp)
    8000453a:	7442                	ld	s0,48(sp)
    8000453c:	74a2                	ld	s1,40(sp)
    8000453e:	7902                	ld	s2,32(sp)
    80004540:	69e2                	ld	s3,24(sp)
    80004542:	6a42                	ld	s4,16(sp)
    80004544:	6121                	addi	sp,sp,64
    80004546:	8082                	ret
    iput(ip);
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	a2a080e7          	jalr	-1494(ra) # 80003f72 <iput>
    return -1;
    80004550:	557d                	li	a0,-1
    80004552:	b7dd                	j	80004538 <dirlink+0x86>
      panic("dirlink read");
    80004554:	00004517          	auipc	a0,0x4
    80004558:	3f450513          	addi	a0,a0,1012 # 80008948 <syscallnames+0x2d8>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	fe4080e7          	jalr	-28(ra) # 80000540 <panic>

0000000080004564 <namei>:

struct inode*
namei(char *path)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000456c:	fe040613          	addi	a2,s0,-32
    80004570:	4581                	li	a1,0
    80004572:	00000097          	auipc	ra,0x0
    80004576:	dda080e7          	jalr	-550(ra) # 8000434c <namex>
}
    8000457a:	60e2                	ld	ra,24(sp)
    8000457c:	6442                	ld	s0,16(sp)
    8000457e:	6105                	addi	sp,sp,32
    80004580:	8082                	ret

0000000080004582 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004582:	1141                	addi	sp,sp,-16
    80004584:	e406                	sd	ra,8(sp)
    80004586:	e022                	sd	s0,0(sp)
    80004588:	0800                	addi	s0,sp,16
    8000458a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000458c:	4585                	li	a1,1
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	dbe080e7          	jalr	-578(ra) # 8000434c <namex>
}
    80004596:	60a2                	ld	ra,8(sp)
    80004598:	6402                	ld	s0,0(sp)
    8000459a:	0141                	addi	sp,sp,16
    8000459c:	8082                	ret

000000008000459e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	e04a                	sd	s2,0(sp)
    800045a8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045aa:	0023d917          	auipc	s2,0x23d
    800045ae:	6a690913          	addi	s2,s2,1702 # 80241c50 <log>
    800045b2:	01892583          	lw	a1,24(s2)
    800045b6:	02892503          	lw	a0,40(s2)
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	fe6080e7          	jalr	-26(ra) # 800035a0 <bread>
    800045c2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045c4:	02c92683          	lw	a3,44(s2)
    800045c8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045ca:	02d05863          	blez	a3,800045fa <write_head+0x5c>
    800045ce:	0023d797          	auipc	a5,0x23d
    800045d2:	6b278793          	addi	a5,a5,1714 # 80241c80 <log+0x30>
    800045d6:	05c50713          	addi	a4,a0,92
    800045da:	36fd                	addiw	a3,a3,-1
    800045dc:	02069613          	slli	a2,a3,0x20
    800045e0:	01e65693          	srli	a3,a2,0x1e
    800045e4:	0023d617          	auipc	a2,0x23d
    800045e8:	6a060613          	addi	a2,a2,1696 # 80241c84 <log+0x34>
    800045ec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045ee:	4390                	lw	a2,0(a5)
    800045f0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045f2:	0791                	addi	a5,a5,4
    800045f4:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800045f6:	fed79ce3          	bne	a5,a3,800045ee <write_head+0x50>
  }
  bwrite(buf);
    800045fa:	8526                	mv	a0,s1
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	096080e7          	jalr	150(ra) # 80003692 <bwrite>
  brelse(buf);
    80004604:	8526                	mv	a0,s1
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	0ca080e7          	jalr	202(ra) # 800036d0 <brelse>
}
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6902                	ld	s2,0(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret

000000008000461a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000461a:	0023d797          	auipc	a5,0x23d
    8000461e:	6627a783          	lw	a5,1634(a5) # 80241c7c <log+0x2c>
    80004622:	0af05d63          	blez	a5,800046dc <install_trans+0xc2>
{
    80004626:	7139                	addi	sp,sp,-64
    80004628:	fc06                	sd	ra,56(sp)
    8000462a:	f822                	sd	s0,48(sp)
    8000462c:	f426                	sd	s1,40(sp)
    8000462e:	f04a                	sd	s2,32(sp)
    80004630:	ec4e                	sd	s3,24(sp)
    80004632:	e852                	sd	s4,16(sp)
    80004634:	e456                	sd	s5,8(sp)
    80004636:	e05a                	sd	s6,0(sp)
    80004638:	0080                	addi	s0,sp,64
    8000463a:	8b2a                	mv	s6,a0
    8000463c:	0023da97          	auipc	s5,0x23d
    80004640:	644a8a93          	addi	s5,s5,1604 # 80241c80 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004644:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004646:	0023d997          	auipc	s3,0x23d
    8000464a:	60a98993          	addi	s3,s3,1546 # 80241c50 <log>
    8000464e:	a00d                	j	80004670 <install_trans+0x56>
    brelse(lbuf);
    80004650:	854a                	mv	a0,s2
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	07e080e7          	jalr	126(ra) # 800036d0 <brelse>
    brelse(dbuf);
    8000465a:	8526                	mv	a0,s1
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	074080e7          	jalr	116(ra) # 800036d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004664:	2a05                	addiw	s4,s4,1
    80004666:	0a91                	addi	s5,s5,4
    80004668:	02c9a783          	lw	a5,44(s3)
    8000466c:	04fa5e63          	bge	s4,a5,800046c8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004670:	0189a583          	lw	a1,24(s3)
    80004674:	014585bb          	addw	a1,a1,s4
    80004678:	2585                	addiw	a1,a1,1
    8000467a:	0289a503          	lw	a0,40(s3)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	f22080e7          	jalr	-222(ra) # 800035a0 <bread>
    80004686:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004688:	000aa583          	lw	a1,0(s5)
    8000468c:	0289a503          	lw	a0,40(s3)
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	f10080e7          	jalr	-240(ra) # 800035a0 <bread>
    80004698:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000469a:	40000613          	li	a2,1024
    8000469e:	05890593          	addi	a1,s2,88
    800046a2:	05850513          	addi	a0,a0,88
    800046a6:	ffffd097          	auipc	ra,0xffffd
    800046aa:	834080e7          	jalr	-1996(ra) # 80000eda <memmove>
    bwrite(dbuf);  // write dst to disk
    800046ae:	8526                	mv	a0,s1
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	fe2080e7          	jalr	-30(ra) # 80003692 <bwrite>
    if(recovering == 0)
    800046b8:	f80b1ce3          	bnez	s6,80004650 <install_trans+0x36>
      bunpin(dbuf);
    800046bc:	8526                	mv	a0,s1
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	0ec080e7          	jalr	236(ra) # 800037aa <bunpin>
    800046c6:	b769                	j	80004650 <install_trans+0x36>
}
    800046c8:	70e2                	ld	ra,56(sp)
    800046ca:	7442                	ld	s0,48(sp)
    800046cc:	74a2                	ld	s1,40(sp)
    800046ce:	7902                	ld	s2,32(sp)
    800046d0:	69e2                	ld	s3,24(sp)
    800046d2:	6a42                	ld	s4,16(sp)
    800046d4:	6aa2                	ld	s5,8(sp)
    800046d6:	6b02                	ld	s6,0(sp)
    800046d8:	6121                	addi	sp,sp,64
    800046da:	8082                	ret
    800046dc:	8082                	ret

00000000800046de <initlog>:
{
    800046de:	7179                	addi	sp,sp,-48
    800046e0:	f406                	sd	ra,40(sp)
    800046e2:	f022                	sd	s0,32(sp)
    800046e4:	ec26                	sd	s1,24(sp)
    800046e6:	e84a                	sd	s2,16(sp)
    800046e8:	e44e                	sd	s3,8(sp)
    800046ea:	1800                	addi	s0,sp,48
    800046ec:	892a                	mv	s2,a0
    800046ee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046f0:	0023d497          	auipc	s1,0x23d
    800046f4:	56048493          	addi	s1,s1,1376 # 80241c50 <log>
    800046f8:	00004597          	auipc	a1,0x4
    800046fc:	26058593          	addi	a1,a1,608 # 80008958 <syscallnames+0x2e8>
    80004700:	8526                	mv	a0,s1
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	5f0080e7          	jalr	1520(ra) # 80000cf2 <initlock>
  log.start = sb->logstart;
    8000470a:	0149a583          	lw	a1,20(s3)
    8000470e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004710:	0109a783          	lw	a5,16(s3)
    80004714:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004716:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000471a:	854a                	mv	a0,s2
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	e84080e7          	jalr	-380(ra) # 800035a0 <bread>
  log.lh.n = lh->n;
    80004724:	4d34                	lw	a3,88(a0)
    80004726:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004728:	02d05663          	blez	a3,80004754 <initlog+0x76>
    8000472c:	05c50793          	addi	a5,a0,92
    80004730:	0023d717          	auipc	a4,0x23d
    80004734:	55070713          	addi	a4,a4,1360 # 80241c80 <log+0x30>
    80004738:	36fd                	addiw	a3,a3,-1
    8000473a:	02069613          	slli	a2,a3,0x20
    8000473e:	01e65693          	srli	a3,a2,0x1e
    80004742:	06050613          	addi	a2,a0,96
    80004746:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004748:	4390                	lw	a2,0(a5)
    8000474a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000474c:	0791                	addi	a5,a5,4
    8000474e:	0711                	addi	a4,a4,4
    80004750:	fed79ce3          	bne	a5,a3,80004748 <initlog+0x6a>
  brelse(buf);
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	f7c080e7          	jalr	-132(ra) # 800036d0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000475c:	4505                	li	a0,1
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	ebc080e7          	jalr	-324(ra) # 8000461a <install_trans>
  log.lh.n = 0;
    80004766:	0023d797          	auipc	a5,0x23d
    8000476a:	5007ab23          	sw	zero,1302(a5) # 80241c7c <log+0x2c>
  write_head(); // clear the log
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	e30080e7          	jalr	-464(ra) # 8000459e <write_head>
}
    80004776:	70a2                	ld	ra,40(sp)
    80004778:	7402                	ld	s0,32(sp)
    8000477a:	64e2                	ld	s1,24(sp)
    8000477c:	6942                	ld	s2,16(sp)
    8000477e:	69a2                	ld	s3,8(sp)
    80004780:	6145                	addi	sp,sp,48
    80004782:	8082                	ret

0000000080004784 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004784:	1101                	addi	sp,sp,-32
    80004786:	ec06                	sd	ra,24(sp)
    80004788:	e822                	sd	s0,16(sp)
    8000478a:	e426                	sd	s1,8(sp)
    8000478c:	e04a                	sd	s2,0(sp)
    8000478e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004790:	0023d517          	auipc	a0,0x23d
    80004794:	4c050513          	addi	a0,a0,1216 # 80241c50 <log>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	5ea080e7          	jalr	1514(ra) # 80000d82 <acquire>
  while(1){
    if(log.committing){
    800047a0:	0023d497          	auipc	s1,0x23d
    800047a4:	4b048493          	addi	s1,s1,1200 # 80241c50 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047a8:	4979                	li	s2,30
    800047aa:	a039                	j	800047b8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047ac:	85a6                	mv	a1,s1
    800047ae:	8526                	mv	a0,s1
    800047b0:	ffffe097          	auipc	ra,0xffffe
    800047b4:	b0c080e7          	jalr	-1268(ra) # 800022bc <sleep>
    if(log.committing){
    800047b8:	50dc                	lw	a5,36(s1)
    800047ba:	fbed                	bnez	a5,800047ac <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047bc:	5098                	lw	a4,32(s1)
    800047be:	2705                	addiw	a4,a4,1
    800047c0:	0007069b          	sext.w	a3,a4
    800047c4:	0027179b          	slliw	a5,a4,0x2
    800047c8:	9fb9                	addw	a5,a5,a4
    800047ca:	0017979b          	slliw	a5,a5,0x1
    800047ce:	54d8                	lw	a4,44(s1)
    800047d0:	9fb9                	addw	a5,a5,a4
    800047d2:	00f95963          	bge	s2,a5,800047e4 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047d6:	85a6                	mv	a1,s1
    800047d8:	8526                	mv	a0,s1
    800047da:	ffffe097          	auipc	ra,0xffffe
    800047de:	ae2080e7          	jalr	-1310(ra) # 800022bc <sleep>
    800047e2:	bfd9                	j	800047b8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047e4:	0023d517          	auipc	a0,0x23d
    800047e8:	46c50513          	addi	a0,a0,1132 # 80241c50 <log>
    800047ec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	648080e7          	jalr	1608(ra) # 80000e36 <release>
      break;
    }
  }
}
    800047f6:	60e2                	ld	ra,24(sp)
    800047f8:	6442                	ld	s0,16(sp)
    800047fa:	64a2                	ld	s1,8(sp)
    800047fc:	6902                	ld	s2,0(sp)
    800047fe:	6105                	addi	sp,sp,32
    80004800:	8082                	ret

0000000080004802 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004802:	7139                	addi	sp,sp,-64
    80004804:	fc06                	sd	ra,56(sp)
    80004806:	f822                	sd	s0,48(sp)
    80004808:	f426                	sd	s1,40(sp)
    8000480a:	f04a                	sd	s2,32(sp)
    8000480c:	ec4e                	sd	s3,24(sp)
    8000480e:	e852                	sd	s4,16(sp)
    80004810:	e456                	sd	s5,8(sp)
    80004812:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004814:	0023d497          	auipc	s1,0x23d
    80004818:	43c48493          	addi	s1,s1,1084 # 80241c50 <log>
    8000481c:	8526                	mv	a0,s1
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	564080e7          	jalr	1380(ra) # 80000d82 <acquire>
  log.outstanding -= 1;
    80004826:	509c                	lw	a5,32(s1)
    80004828:	37fd                	addiw	a5,a5,-1
    8000482a:	0007891b          	sext.w	s2,a5
    8000482e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004830:	50dc                	lw	a5,36(s1)
    80004832:	e7b9                	bnez	a5,80004880 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004834:	04091e63          	bnez	s2,80004890 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004838:	0023d497          	auipc	s1,0x23d
    8000483c:	41848493          	addi	s1,s1,1048 # 80241c50 <log>
    80004840:	4785                	li	a5,1
    80004842:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004844:	8526                	mv	a0,s1
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	5f0080e7          	jalr	1520(ra) # 80000e36 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000484e:	54dc                	lw	a5,44(s1)
    80004850:	06f04763          	bgtz	a5,800048be <end_op+0xbc>
    acquire(&log.lock);
    80004854:	0023d497          	auipc	s1,0x23d
    80004858:	3fc48493          	addi	s1,s1,1020 # 80241c50 <log>
    8000485c:	8526                	mv	a0,s1
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	524080e7          	jalr	1316(ra) # 80000d82 <acquire>
    log.committing = 0;
    80004866:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000486a:	8526                	mv	a0,s1
    8000486c:	ffffe097          	auipc	ra,0xffffe
    80004870:	c00080e7          	jalr	-1024(ra) # 8000246c <wakeup>
    release(&log.lock);
    80004874:	8526                	mv	a0,s1
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	5c0080e7          	jalr	1472(ra) # 80000e36 <release>
}
    8000487e:	a03d                	j	800048ac <end_op+0xaa>
    panic("log.committing");
    80004880:	00004517          	auipc	a0,0x4
    80004884:	0e050513          	addi	a0,a0,224 # 80008960 <syscallnames+0x2f0>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	cb8080e7          	jalr	-840(ra) # 80000540 <panic>
    wakeup(&log);
    80004890:	0023d497          	auipc	s1,0x23d
    80004894:	3c048493          	addi	s1,s1,960 # 80241c50 <log>
    80004898:	8526                	mv	a0,s1
    8000489a:	ffffe097          	auipc	ra,0xffffe
    8000489e:	bd2080e7          	jalr	-1070(ra) # 8000246c <wakeup>
  release(&log.lock);
    800048a2:	8526                	mv	a0,s1
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	592080e7          	jalr	1426(ra) # 80000e36 <release>
}
    800048ac:	70e2                	ld	ra,56(sp)
    800048ae:	7442                	ld	s0,48(sp)
    800048b0:	74a2                	ld	s1,40(sp)
    800048b2:	7902                	ld	s2,32(sp)
    800048b4:	69e2                	ld	s3,24(sp)
    800048b6:	6a42                	ld	s4,16(sp)
    800048b8:	6aa2                	ld	s5,8(sp)
    800048ba:	6121                	addi	sp,sp,64
    800048bc:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800048be:	0023da97          	auipc	s5,0x23d
    800048c2:	3c2a8a93          	addi	s5,s5,962 # 80241c80 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048c6:	0023da17          	auipc	s4,0x23d
    800048ca:	38aa0a13          	addi	s4,s4,906 # 80241c50 <log>
    800048ce:	018a2583          	lw	a1,24(s4)
    800048d2:	012585bb          	addw	a1,a1,s2
    800048d6:	2585                	addiw	a1,a1,1
    800048d8:	028a2503          	lw	a0,40(s4)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	cc4080e7          	jalr	-828(ra) # 800035a0 <bread>
    800048e4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048e6:	000aa583          	lw	a1,0(s5)
    800048ea:	028a2503          	lw	a0,40(s4)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	cb2080e7          	jalr	-846(ra) # 800035a0 <bread>
    800048f6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048f8:	40000613          	li	a2,1024
    800048fc:	05850593          	addi	a1,a0,88
    80004900:	05848513          	addi	a0,s1,88
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	5d6080e7          	jalr	1494(ra) # 80000eda <memmove>
    bwrite(to);  // write the log
    8000490c:	8526                	mv	a0,s1
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	d84080e7          	jalr	-636(ra) # 80003692 <bwrite>
    brelse(from);
    80004916:	854e                	mv	a0,s3
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	db8080e7          	jalr	-584(ra) # 800036d0 <brelse>
    brelse(to);
    80004920:	8526                	mv	a0,s1
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	dae080e7          	jalr	-594(ra) # 800036d0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000492a:	2905                	addiw	s2,s2,1
    8000492c:	0a91                	addi	s5,s5,4
    8000492e:	02ca2783          	lw	a5,44(s4)
    80004932:	f8f94ee3          	blt	s2,a5,800048ce <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	c68080e7          	jalr	-920(ra) # 8000459e <write_head>
    install_trans(0); // Now install writes to home locations
    8000493e:	4501                	li	a0,0
    80004940:	00000097          	auipc	ra,0x0
    80004944:	cda080e7          	jalr	-806(ra) # 8000461a <install_trans>
    log.lh.n = 0;
    80004948:	0023d797          	auipc	a5,0x23d
    8000494c:	3207aa23          	sw	zero,820(a5) # 80241c7c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004950:	00000097          	auipc	ra,0x0
    80004954:	c4e080e7          	jalr	-946(ra) # 8000459e <write_head>
    80004958:	bdf5                	j	80004854 <end_op+0x52>

000000008000495a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000495a:	1101                	addi	sp,sp,-32
    8000495c:	ec06                	sd	ra,24(sp)
    8000495e:	e822                	sd	s0,16(sp)
    80004960:	e426                	sd	s1,8(sp)
    80004962:	e04a                	sd	s2,0(sp)
    80004964:	1000                	addi	s0,sp,32
    80004966:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004968:	0023d917          	auipc	s2,0x23d
    8000496c:	2e890913          	addi	s2,s2,744 # 80241c50 <log>
    80004970:	854a                	mv	a0,s2
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	410080e7          	jalr	1040(ra) # 80000d82 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000497a:	02c92603          	lw	a2,44(s2)
    8000497e:	47f5                	li	a5,29
    80004980:	06c7c563          	blt	a5,a2,800049ea <log_write+0x90>
    80004984:	0023d797          	auipc	a5,0x23d
    80004988:	2e87a783          	lw	a5,744(a5) # 80241c6c <log+0x1c>
    8000498c:	37fd                	addiw	a5,a5,-1
    8000498e:	04f65e63          	bge	a2,a5,800049ea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004992:	0023d797          	auipc	a5,0x23d
    80004996:	2de7a783          	lw	a5,734(a5) # 80241c70 <log+0x20>
    8000499a:	06f05063          	blez	a5,800049fa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000499e:	4781                	li	a5,0
    800049a0:	06c05563          	blez	a2,80004a0a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049a4:	44cc                	lw	a1,12(s1)
    800049a6:	0023d717          	auipc	a4,0x23d
    800049aa:	2da70713          	addi	a4,a4,730 # 80241c80 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049ae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049b0:	4314                	lw	a3,0(a4)
    800049b2:	04b68c63          	beq	a3,a1,80004a0a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049b6:	2785                	addiw	a5,a5,1
    800049b8:	0711                	addi	a4,a4,4
    800049ba:	fef61be3          	bne	a2,a5,800049b0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049be:	0621                	addi	a2,a2,8
    800049c0:	060a                	slli	a2,a2,0x2
    800049c2:	0023d797          	auipc	a5,0x23d
    800049c6:	28e78793          	addi	a5,a5,654 # 80241c50 <log>
    800049ca:	97b2                	add	a5,a5,a2
    800049cc:	44d8                	lw	a4,12(s1)
    800049ce:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049d0:	8526                	mv	a0,s1
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	d9c080e7          	jalr	-612(ra) # 8000376e <bpin>
    log.lh.n++;
    800049da:	0023d717          	auipc	a4,0x23d
    800049de:	27670713          	addi	a4,a4,630 # 80241c50 <log>
    800049e2:	575c                	lw	a5,44(a4)
    800049e4:	2785                	addiw	a5,a5,1
    800049e6:	d75c                	sw	a5,44(a4)
    800049e8:	a82d                	j	80004a22 <log_write+0xc8>
    panic("too big a transaction");
    800049ea:	00004517          	auipc	a0,0x4
    800049ee:	f8650513          	addi	a0,a0,-122 # 80008970 <syscallnames+0x300>
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	b4e080e7          	jalr	-1202(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800049fa:	00004517          	auipc	a0,0x4
    800049fe:	f8e50513          	addi	a0,a0,-114 # 80008988 <syscallnames+0x318>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	b3e080e7          	jalr	-1218(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004a0a:	00878693          	addi	a3,a5,8
    80004a0e:	068a                	slli	a3,a3,0x2
    80004a10:	0023d717          	auipc	a4,0x23d
    80004a14:	24070713          	addi	a4,a4,576 # 80241c50 <log>
    80004a18:	9736                	add	a4,a4,a3
    80004a1a:	44d4                	lw	a3,12(s1)
    80004a1c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a1e:	faf609e3          	beq	a2,a5,800049d0 <log_write+0x76>
  }
  release(&log.lock);
    80004a22:	0023d517          	auipc	a0,0x23d
    80004a26:	22e50513          	addi	a0,a0,558 # 80241c50 <log>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	40c080e7          	jalr	1036(ra) # 80000e36 <release>
}
    80004a32:	60e2                	ld	ra,24(sp)
    80004a34:	6442                	ld	s0,16(sp)
    80004a36:	64a2                	ld	s1,8(sp)
    80004a38:	6902                	ld	s2,0(sp)
    80004a3a:	6105                	addi	sp,sp,32
    80004a3c:	8082                	ret

0000000080004a3e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a3e:	1101                	addi	sp,sp,-32
    80004a40:	ec06                	sd	ra,24(sp)
    80004a42:	e822                	sd	s0,16(sp)
    80004a44:	e426                	sd	s1,8(sp)
    80004a46:	e04a                	sd	s2,0(sp)
    80004a48:	1000                	addi	s0,sp,32
    80004a4a:	84aa                	mv	s1,a0
    80004a4c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a4e:	00004597          	auipc	a1,0x4
    80004a52:	f5a58593          	addi	a1,a1,-166 # 800089a8 <syscallnames+0x338>
    80004a56:	0521                	addi	a0,a0,8
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	29a080e7          	jalr	666(ra) # 80000cf2 <initlock>
  lk->name = name;
    80004a60:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a64:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a68:	0204a423          	sw	zero,40(s1)
}
    80004a6c:	60e2                	ld	ra,24(sp)
    80004a6e:	6442                	ld	s0,16(sp)
    80004a70:	64a2                	ld	s1,8(sp)
    80004a72:	6902                	ld	s2,0(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret

0000000080004a78 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a78:	1101                	addi	sp,sp,-32
    80004a7a:	ec06                	sd	ra,24(sp)
    80004a7c:	e822                	sd	s0,16(sp)
    80004a7e:	e426                	sd	s1,8(sp)
    80004a80:	e04a                	sd	s2,0(sp)
    80004a82:	1000                	addi	s0,sp,32
    80004a84:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a86:	00850913          	addi	s2,a0,8
    80004a8a:	854a                	mv	a0,s2
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	2f6080e7          	jalr	758(ra) # 80000d82 <acquire>
  while (lk->locked) {
    80004a94:	409c                	lw	a5,0(s1)
    80004a96:	cb89                	beqz	a5,80004aa8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a98:	85ca                	mv	a1,s2
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffe097          	auipc	ra,0xffffe
    80004aa0:	820080e7          	jalr	-2016(ra) # 800022bc <sleep>
  while (lk->locked) {
    80004aa4:	409c                	lw	a5,0(s1)
    80004aa6:	fbed                	bnez	a5,80004a98 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004aa8:	4785                	li	a5,1
    80004aaa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004aac:	ffffd097          	auipc	ra,0xffffd
    80004ab0:	0d6080e7          	jalr	214(ra) # 80001b82 <myproc>
    80004ab4:	591c                	lw	a5,48(a0)
    80004ab6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ab8:	854a                	mv	a0,s2
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	37c080e7          	jalr	892(ra) # 80000e36 <release>
}
    80004ac2:	60e2                	ld	ra,24(sp)
    80004ac4:	6442                	ld	s0,16(sp)
    80004ac6:	64a2                	ld	s1,8(sp)
    80004ac8:	6902                	ld	s2,0(sp)
    80004aca:	6105                	addi	sp,sp,32
    80004acc:	8082                	ret

0000000080004ace <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ace:	1101                	addi	sp,sp,-32
    80004ad0:	ec06                	sd	ra,24(sp)
    80004ad2:	e822                	sd	s0,16(sp)
    80004ad4:	e426                	sd	s1,8(sp)
    80004ad6:	e04a                	sd	s2,0(sp)
    80004ad8:	1000                	addi	s0,sp,32
    80004ada:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004adc:	00850913          	addi	s2,a0,8
    80004ae0:	854a                	mv	a0,s2
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	2a0080e7          	jalr	672(ra) # 80000d82 <acquire>
  lk->locked = 0;
    80004aea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aee:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004af2:	8526                	mv	a0,s1
    80004af4:	ffffe097          	auipc	ra,0xffffe
    80004af8:	978080e7          	jalr	-1672(ra) # 8000246c <wakeup>
  release(&lk->lk);
    80004afc:	854a                	mv	a0,s2
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	338080e7          	jalr	824(ra) # 80000e36 <release>
}
    80004b06:	60e2                	ld	ra,24(sp)
    80004b08:	6442                	ld	s0,16(sp)
    80004b0a:	64a2                	ld	s1,8(sp)
    80004b0c:	6902                	ld	s2,0(sp)
    80004b0e:	6105                	addi	sp,sp,32
    80004b10:	8082                	ret

0000000080004b12 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b12:	7179                	addi	sp,sp,-48
    80004b14:	f406                	sd	ra,40(sp)
    80004b16:	f022                	sd	s0,32(sp)
    80004b18:	ec26                	sd	s1,24(sp)
    80004b1a:	e84a                	sd	s2,16(sp)
    80004b1c:	e44e                	sd	s3,8(sp)
    80004b1e:	1800                	addi	s0,sp,48
    80004b20:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b22:	00850913          	addi	s2,a0,8
    80004b26:	854a                	mv	a0,s2
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	25a080e7          	jalr	602(ra) # 80000d82 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b30:	409c                	lw	a5,0(s1)
    80004b32:	ef99                	bnez	a5,80004b50 <holdingsleep+0x3e>
    80004b34:	4481                	li	s1,0
  release(&lk->lk);
    80004b36:	854a                	mv	a0,s2
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	2fe080e7          	jalr	766(ra) # 80000e36 <release>
  return r;
}
    80004b40:	8526                	mv	a0,s1
    80004b42:	70a2                	ld	ra,40(sp)
    80004b44:	7402                	ld	s0,32(sp)
    80004b46:	64e2                	ld	s1,24(sp)
    80004b48:	6942                	ld	s2,16(sp)
    80004b4a:	69a2                	ld	s3,8(sp)
    80004b4c:	6145                	addi	sp,sp,48
    80004b4e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b50:	0284a983          	lw	s3,40(s1)
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	02e080e7          	jalr	46(ra) # 80001b82 <myproc>
    80004b5c:	5904                	lw	s1,48(a0)
    80004b5e:	413484b3          	sub	s1,s1,s3
    80004b62:	0014b493          	seqz	s1,s1
    80004b66:	bfc1                	j	80004b36 <holdingsleep+0x24>

0000000080004b68 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b68:	1141                	addi	sp,sp,-16
    80004b6a:	e406                	sd	ra,8(sp)
    80004b6c:	e022                	sd	s0,0(sp)
    80004b6e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b70:	00004597          	auipc	a1,0x4
    80004b74:	e4858593          	addi	a1,a1,-440 # 800089b8 <syscallnames+0x348>
    80004b78:	0023d517          	auipc	a0,0x23d
    80004b7c:	22050513          	addi	a0,a0,544 # 80241d98 <ftable>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	172080e7          	jalr	370(ra) # 80000cf2 <initlock>
}
    80004b88:	60a2                	ld	ra,8(sp)
    80004b8a:	6402                	ld	s0,0(sp)
    80004b8c:	0141                	addi	sp,sp,16
    80004b8e:	8082                	ret

0000000080004b90 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b90:	1101                	addi	sp,sp,-32
    80004b92:	ec06                	sd	ra,24(sp)
    80004b94:	e822                	sd	s0,16(sp)
    80004b96:	e426                	sd	s1,8(sp)
    80004b98:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b9a:	0023d517          	auipc	a0,0x23d
    80004b9e:	1fe50513          	addi	a0,a0,510 # 80241d98 <ftable>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	1e0080e7          	jalr	480(ra) # 80000d82 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004baa:	0023d497          	auipc	s1,0x23d
    80004bae:	20648493          	addi	s1,s1,518 # 80241db0 <ftable+0x18>
    80004bb2:	0023e717          	auipc	a4,0x23e
    80004bb6:	19e70713          	addi	a4,a4,414 # 80242d50 <disk>
    if(f->ref == 0){
    80004bba:	40dc                	lw	a5,4(s1)
    80004bbc:	cf99                	beqz	a5,80004bda <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bbe:	02848493          	addi	s1,s1,40
    80004bc2:	fee49ce3          	bne	s1,a4,80004bba <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bc6:	0023d517          	auipc	a0,0x23d
    80004bca:	1d250513          	addi	a0,a0,466 # 80241d98 <ftable>
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	268080e7          	jalr	616(ra) # 80000e36 <release>
  return 0;
    80004bd6:	4481                	li	s1,0
    80004bd8:	a819                	j	80004bee <filealloc+0x5e>
      f->ref = 1;
    80004bda:	4785                	li	a5,1
    80004bdc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bde:	0023d517          	auipc	a0,0x23d
    80004be2:	1ba50513          	addi	a0,a0,442 # 80241d98 <ftable>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	250080e7          	jalr	592(ra) # 80000e36 <release>
}
    80004bee:	8526                	mv	a0,s1
    80004bf0:	60e2                	ld	ra,24(sp)
    80004bf2:	6442                	ld	s0,16(sp)
    80004bf4:	64a2                	ld	s1,8(sp)
    80004bf6:	6105                	addi	sp,sp,32
    80004bf8:	8082                	ret

0000000080004bfa <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bfa:	1101                	addi	sp,sp,-32
    80004bfc:	ec06                	sd	ra,24(sp)
    80004bfe:	e822                	sd	s0,16(sp)
    80004c00:	e426                	sd	s1,8(sp)
    80004c02:	1000                	addi	s0,sp,32
    80004c04:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c06:	0023d517          	auipc	a0,0x23d
    80004c0a:	19250513          	addi	a0,a0,402 # 80241d98 <ftable>
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	174080e7          	jalr	372(ra) # 80000d82 <acquire>
  if(f->ref < 1)
    80004c16:	40dc                	lw	a5,4(s1)
    80004c18:	02f05263          	blez	a5,80004c3c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c1c:	2785                	addiw	a5,a5,1
    80004c1e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c20:	0023d517          	auipc	a0,0x23d
    80004c24:	17850513          	addi	a0,a0,376 # 80241d98 <ftable>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	20e080e7          	jalr	526(ra) # 80000e36 <release>
  return f;
}
    80004c30:	8526                	mv	a0,s1
    80004c32:	60e2                	ld	ra,24(sp)
    80004c34:	6442                	ld	s0,16(sp)
    80004c36:	64a2                	ld	s1,8(sp)
    80004c38:	6105                	addi	sp,sp,32
    80004c3a:	8082                	ret
    panic("filedup");
    80004c3c:	00004517          	auipc	a0,0x4
    80004c40:	d8450513          	addi	a0,a0,-636 # 800089c0 <syscallnames+0x350>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	8fc080e7          	jalr	-1796(ra) # 80000540 <panic>

0000000080004c4c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c4c:	7139                	addi	sp,sp,-64
    80004c4e:	fc06                	sd	ra,56(sp)
    80004c50:	f822                	sd	s0,48(sp)
    80004c52:	f426                	sd	s1,40(sp)
    80004c54:	f04a                	sd	s2,32(sp)
    80004c56:	ec4e                	sd	s3,24(sp)
    80004c58:	e852                	sd	s4,16(sp)
    80004c5a:	e456                	sd	s5,8(sp)
    80004c5c:	0080                	addi	s0,sp,64
    80004c5e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c60:	0023d517          	auipc	a0,0x23d
    80004c64:	13850513          	addi	a0,a0,312 # 80241d98 <ftable>
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	11a080e7          	jalr	282(ra) # 80000d82 <acquire>
  if(f->ref < 1)
    80004c70:	40dc                	lw	a5,4(s1)
    80004c72:	06f05163          	blez	a5,80004cd4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c76:	37fd                	addiw	a5,a5,-1
    80004c78:	0007871b          	sext.w	a4,a5
    80004c7c:	c0dc                	sw	a5,4(s1)
    80004c7e:	06e04363          	bgtz	a4,80004ce4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c82:	0004a903          	lw	s2,0(s1)
    80004c86:	0094ca83          	lbu	s5,9(s1)
    80004c8a:	0104ba03          	ld	s4,16(s1)
    80004c8e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c92:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c96:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c9a:	0023d517          	auipc	a0,0x23d
    80004c9e:	0fe50513          	addi	a0,a0,254 # 80241d98 <ftable>
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	194080e7          	jalr	404(ra) # 80000e36 <release>

  if(ff.type == FD_PIPE){
    80004caa:	4785                	li	a5,1
    80004cac:	04f90d63          	beq	s2,a5,80004d06 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cb0:	3979                	addiw	s2,s2,-2
    80004cb2:	4785                	li	a5,1
    80004cb4:	0527e063          	bltu	a5,s2,80004cf4 <fileclose+0xa8>
    begin_op();
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	acc080e7          	jalr	-1332(ra) # 80004784 <begin_op>
    iput(ff.ip);
    80004cc0:	854e                	mv	a0,s3
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	2b0080e7          	jalr	688(ra) # 80003f72 <iput>
    end_op();
    80004cca:	00000097          	auipc	ra,0x0
    80004cce:	b38080e7          	jalr	-1224(ra) # 80004802 <end_op>
    80004cd2:	a00d                	j	80004cf4 <fileclose+0xa8>
    panic("fileclose");
    80004cd4:	00004517          	auipc	a0,0x4
    80004cd8:	cf450513          	addi	a0,a0,-780 # 800089c8 <syscallnames+0x358>
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	864080e7          	jalr	-1948(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004ce4:	0023d517          	auipc	a0,0x23d
    80004ce8:	0b450513          	addi	a0,a0,180 # 80241d98 <ftable>
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	14a080e7          	jalr	330(ra) # 80000e36 <release>
  }
}
    80004cf4:	70e2                	ld	ra,56(sp)
    80004cf6:	7442                	ld	s0,48(sp)
    80004cf8:	74a2                	ld	s1,40(sp)
    80004cfa:	7902                	ld	s2,32(sp)
    80004cfc:	69e2                	ld	s3,24(sp)
    80004cfe:	6a42                	ld	s4,16(sp)
    80004d00:	6aa2                	ld	s5,8(sp)
    80004d02:	6121                	addi	sp,sp,64
    80004d04:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d06:	85d6                	mv	a1,s5
    80004d08:	8552                	mv	a0,s4
    80004d0a:	00000097          	auipc	ra,0x0
    80004d0e:	34c080e7          	jalr	844(ra) # 80005056 <pipeclose>
    80004d12:	b7cd                	j	80004cf4 <fileclose+0xa8>

0000000080004d14 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d14:	715d                	addi	sp,sp,-80
    80004d16:	e486                	sd	ra,72(sp)
    80004d18:	e0a2                	sd	s0,64(sp)
    80004d1a:	fc26                	sd	s1,56(sp)
    80004d1c:	f84a                	sd	s2,48(sp)
    80004d1e:	f44e                	sd	s3,40(sp)
    80004d20:	0880                	addi	s0,sp,80
    80004d22:	84aa                	mv	s1,a0
    80004d24:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d26:	ffffd097          	auipc	ra,0xffffd
    80004d2a:	e5c080e7          	jalr	-420(ra) # 80001b82 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d2e:	409c                	lw	a5,0(s1)
    80004d30:	37f9                	addiw	a5,a5,-2
    80004d32:	4705                	li	a4,1
    80004d34:	04f76763          	bltu	a4,a5,80004d82 <filestat+0x6e>
    80004d38:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d3a:	6c88                	ld	a0,24(s1)
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	07c080e7          	jalr	124(ra) # 80003db8 <ilock>
    stati(f->ip, &st);
    80004d44:	fb840593          	addi	a1,s0,-72
    80004d48:	6c88                	ld	a0,24(s1)
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	2f8080e7          	jalr	760(ra) # 80004042 <stati>
    iunlock(f->ip);
    80004d52:	6c88                	ld	a0,24(s1)
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	126080e7          	jalr	294(ra) # 80003e7a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d5c:	46e1                	li	a3,24
    80004d5e:	fb840613          	addi	a2,s0,-72
    80004d62:	85ce                	mv	a1,s3
    80004d64:	05093503          	ld	a0,80(s2)
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	aa6080e7          	jalr	-1370(ra) # 8000180e <copyout>
    80004d70:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d74:	60a6                	ld	ra,72(sp)
    80004d76:	6406                	ld	s0,64(sp)
    80004d78:	74e2                	ld	s1,56(sp)
    80004d7a:	7942                	ld	s2,48(sp)
    80004d7c:	79a2                	ld	s3,40(sp)
    80004d7e:	6161                	addi	sp,sp,80
    80004d80:	8082                	ret
  return -1;
    80004d82:	557d                	li	a0,-1
    80004d84:	bfc5                	j	80004d74 <filestat+0x60>

0000000080004d86 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d86:	7179                	addi	sp,sp,-48
    80004d88:	f406                	sd	ra,40(sp)
    80004d8a:	f022                	sd	s0,32(sp)
    80004d8c:	ec26                	sd	s1,24(sp)
    80004d8e:	e84a                	sd	s2,16(sp)
    80004d90:	e44e                	sd	s3,8(sp)
    80004d92:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d94:	00854783          	lbu	a5,8(a0)
    80004d98:	c3d5                	beqz	a5,80004e3c <fileread+0xb6>
    80004d9a:	84aa                	mv	s1,a0
    80004d9c:	89ae                	mv	s3,a1
    80004d9e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004da0:	411c                	lw	a5,0(a0)
    80004da2:	4705                	li	a4,1
    80004da4:	04e78963          	beq	a5,a4,80004df6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004da8:	470d                	li	a4,3
    80004daa:	04e78d63          	beq	a5,a4,80004e04 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dae:	4709                	li	a4,2
    80004db0:	06e79e63          	bne	a5,a4,80004e2c <fileread+0xa6>
    ilock(f->ip);
    80004db4:	6d08                	ld	a0,24(a0)
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	002080e7          	jalr	2(ra) # 80003db8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dbe:	874a                	mv	a4,s2
    80004dc0:	5094                	lw	a3,32(s1)
    80004dc2:	864e                	mv	a2,s3
    80004dc4:	4585                	li	a1,1
    80004dc6:	6c88                	ld	a0,24(s1)
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	2a4080e7          	jalr	676(ra) # 8000406c <readi>
    80004dd0:	892a                	mv	s2,a0
    80004dd2:	00a05563          	blez	a0,80004ddc <fileread+0x56>
      f->off += r;
    80004dd6:	509c                	lw	a5,32(s1)
    80004dd8:	9fa9                	addw	a5,a5,a0
    80004dda:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ddc:	6c88                	ld	a0,24(s1)
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	09c080e7          	jalr	156(ra) # 80003e7a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004de6:	854a                	mv	a0,s2
    80004de8:	70a2                	ld	ra,40(sp)
    80004dea:	7402                	ld	s0,32(sp)
    80004dec:	64e2                	ld	s1,24(sp)
    80004dee:	6942                	ld	s2,16(sp)
    80004df0:	69a2                	ld	s3,8(sp)
    80004df2:	6145                	addi	sp,sp,48
    80004df4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004df6:	6908                	ld	a0,16(a0)
    80004df8:	00000097          	auipc	ra,0x0
    80004dfc:	3c6080e7          	jalr	966(ra) # 800051be <piperead>
    80004e00:	892a                	mv	s2,a0
    80004e02:	b7d5                	j	80004de6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e04:	02451783          	lh	a5,36(a0)
    80004e08:	03079693          	slli	a3,a5,0x30
    80004e0c:	92c1                	srli	a3,a3,0x30
    80004e0e:	4725                	li	a4,9
    80004e10:	02d76863          	bltu	a4,a3,80004e40 <fileread+0xba>
    80004e14:	0792                	slli	a5,a5,0x4
    80004e16:	0023d717          	auipc	a4,0x23d
    80004e1a:	ee270713          	addi	a4,a4,-286 # 80241cf8 <devsw>
    80004e1e:	97ba                	add	a5,a5,a4
    80004e20:	639c                	ld	a5,0(a5)
    80004e22:	c38d                	beqz	a5,80004e44 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e24:	4505                	li	a0,1
    80004e26:	9782                	jalr	a5
    80004e28:	892a                	mv	s2,a0
    80004e2a:	bf75                	j	80004de6 <fileread+0x60>
    panic("fileread");
    80004e2c:	00004517          	auipc	a0,0x4
    80004e30:	bac50513          	addi	a0,a0,-1108 # 800089d8 <syscallnames+0x368>
    80004e34:	ffffb097          	auipc	ra,0xffffb
    80004e38:	70c080e7          	jalr	1804(ra) # 80000540 <panic>
    return -1;
    80004e3c:	597d                	li	s2,-1
    80004e3e:	b765                	j	80004de6 <fileread+0x60>
      return -1;
    80004e40:	597d                	li	s2,-1
    80004e42:	b755                	j	80004de6 <fileread+0x60>
    80004e44:	597d                	li	s2,-1
    80004e46:	b745                	j	80004de6 <fileread+0x60>

0000000080004e48 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e48:	715d                	addi	sp,sp,-80
    80004e4a:	e486                	sd	ra,72(sp)
    80004e4c:	e0a2                	sd	s0,64(sp)
    80004e4e:	fc26                	sd	s1,56(sp)
    80004e50:	f84a                	sd	s2,48(sp)
    80004e52:	f44e                	sd	s3,40(sp)
    80004e54:	f052                	sd	s4,32(sp)
    80004e56:	ec56                	sd	s5,24(sp)
    80004e58:	e85a                	sd	s6,16(sp)
    80004e5a:	e45e                	sd	s7,8(sp)
    80004e5c:	e062                	sd	s8,0(sp)
    80004e5e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e60:	00954783          	lbu	a5,9(a0)
    80004e64:	10078663          	beqz	a5,80004f70 <filewrite+0x128>
    80004e68:	892a                	mv	s2,a0
    80004e6a:	8b2e                	mv	s6,a1
    80004e6c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e6e:	411c                	lw	a5,0(a0)
    80004e70:	4705                	li	a4,1
    80004e72:	02e78263          	beq	a5,a4,80004e96 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e76:	470d                	li	a4,3
    80004e78:	02e78663          	beq	a5,a4,80004ea4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e7c:	4709                	li	a4,2
    80004e7e:	0ee79163          	bne	a5,a4,80004f60 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e82:	0ac05d63          	blez	a2,80004f3c <filewrite+0xf4>
    int i = 0;
    80004e86:	4981                	li	s3,0
    80004e88:	6b85                	lui	s7,0x1
    80004e8a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e8e:	6c05                	lui	s8,0x1
    80004e90:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e94:	a861                	j	80004f2c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e96:	6908                	ld	a0,16(a0)
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	22e080e7          	jalr	558(ra) # 800050c6 <pipewrite>
    80004ea0:	8a2a                	mv	s4,a0
    80004ea2:	a045                	j	80004f42 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ea4:	02451783          	lh	a5,36(a0)
    80004ea8:	03079693          	slli	a3,a5,0x30
    80004eac:	92c1                	srli	a3,a3,0x30
    80004eae:	4725                	li	a4,9
    80004eb0:	0cd76263          	bltu	a4,a3,80004f74 <filewrite+0x12c>
    80004eb4:	0792                	slli	a5,a5,0x4
    80004eb6:	0023d717          	auipc	a4,0x23d
    80004eba:	e4270713          	addi	a4,a4,-446 # 80241cf8 <devsw>
    80004ebe:	97ba                	add	a5,a5,a4
    80004ec0:	679c                	ld	a5,8(a5)
    80004ec2:	cbdd                	beqz	a5,80004f78 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ec4:	4505                	li	a0,1
    80004ec6:	9782                	jalr	a5
    80004ec8:	8a2a                	mv	s4,a0
    80004eca:	a8a5                	j	80004f42 <filewrite+0xfa>
    80004ecc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	8b4080e7          	jalr	-1868(ra) # 80004784 <begin_op>
      ilock(f->ip);
    80004ed8:	01893503          	ld	a0,24(s2)
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	edc080e7          	jalr	-292(ra) # 80003db8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ee4:	8756                	mv	a4,s5
    80004ee6:	02092683          	lw	a3,32(s2)
    80004eea:	01698633          	add	a2,s3,s6
    80004eee:	4585                	li	a1,1
    80004ef0:	01893503          	ld	a0,24(s2)
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	270080e7          	jalr	624(ra) # 80004164 <writei>
    80004efc:	84aa                	mv	s1,a0
    80004efe:	00a05763          	blez	a0,80004f0c <filewrite+0xc4>
        f->off += r;
    80004f02:	02092783          	lw	a5,32(s2)
    80004f06:	9fa9                	addw	a5,a5,a0
    80004f08:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f0c:	01893503          	ld	a0,24(s2)
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	f6a080e7          	jalr	-150(ra) # 80003e7a <iunlock>
      end_op();
    80004f18:	00000097          	auipc	ra,0x0
    80004f1c:	8ea080e7          	jalr	-1814(ra) # 80004802 <end_op>

      if(r != n1){
    80004f20:	009a9f63          	bne	s5,s1,80004f3e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f24:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f28:	0149db63          	bge	s3,s4,80004f3e <filewrite+0xf6>
      int n1 = n - i;
    80004f2c:	413a04bb          	subw	s1,s4,s3
    80004f30:	0004879b          	sext.w	a5,s1
    80004f34:	f8fbdce3          	bge	s7,a5,80004ecc <filewrite+0x84>
    80004f38:	84e2                	mv	s1,s8
    80004f3a:	bf49                	j	80004ecc <filewrite+0x84>
    int i = 0;
    80004f3c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f3e:	013a1f63          	bne	s4,s3,80004f5c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f42:	8552                	mv	a0,s4
    80004f44:	60a6                	ld	ra,72(sp)
    80004f46:	6406                	ld	s0,64(sp)
    80004f48:	74e2                	ld	s1,56(sp)
    80004f4a:	7942                	ld	s2,48(sp)
    80004f4c:	79a2                	ld	s3,40(sp)
    80004f4e:	7a02                	ld	s4,32(sp)
    80004f50:	6ae2                	ld	s5,24(sp)
    80004f52:	6b42                	ld	s6,16(sp)
    80004f54:	6ba2                	ld	s7,8(sp)
    80004f56:	6c02                	ld	s8,0(sp)
    80004f58:	6161                	addi	sp,sp,80
    80004f5a:	8082                	ret
    ret = (i == n ? n : -1);
    80004f5c:	5a7d                	li	s4,-1
    80004f5e:	b7d5                	j	80004f42 <filewrite+0xfa>
    panic("filewrite");
    80004f60:	00004517          	auipc	a0,0x4
    80004f64:	a8850513          	addi	a0,a0,-1400 # 800089e8 <syscallnames+0x378>
    80004f68:	ffffb097          	auipc	ra,0xffffb
    80004f6c:	5d8080e7          	jalr	1496(ra) # 80000540 <panic>
    return -1;
    80004f70:	5a7d                	li	s4,-1
    80004f72:	bfc1                	j	80004f42 <filewrite+0xfa>
      return -1;
    80004f74:	5a7d                	li	s4,-1
    80004f76:	b7f1                	j	80004f42 <filewrite+0xfa>
    80004f78:	5a7d                	li	s4,-1
    80004f7a:	b7e1                	j	80004f42 <filewrite+0xfa>

0000000080004f7c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f7c:	7179                	addi	sp,sp,-48
    80004f7e:	f406                	sd	ra,40(sp)
    80004f80:	f022                	sd	s0,32(sp)
    80004f82:	ec26                	sd	s1,24(sp)
    80004f84:	e84a                	sd	s2,16(sp)
    80004f86:	e44e                	sd	s3,8(sp)
    80004f88:	e052                	sd	s4,0(sp)
    80004f8a:	1800                	addi	s0,sp,48
    80004f8c:	84aa                	mv	s1,a0
    80004f8e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f90:	0005b023          	sd	zero,0(a1)
    80004f94:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f98:	00000097          	auipc	ra,0x0
    80004f9c:	bf8080e7          	jalr	-1032(ra) # 80004b90 <filealloc>
    80004fa0:	e088                	sd	a0,0(s1)
    80004fa2:	c551                	beqz	a0,8000502e <pipealloc+0xb2>
    80004fa4:	00000097          	auipc	ra,0x0
    80004fa8:	bec080e7          	jalr	-1044(ra) # 80004b90 <filealloc>
    80004fac:	00aa3023          	sd	a0,0(s4)
    80004fb0:	c92d                	beqz	a0,80005022 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	ca2080e7          	jalr	-862(ra) # 80000c54 <kalloc>
    80004fba:	892a                	mv	s2,a0
    80004fbc:	c125                	beqz	a0,8000501c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fbe:	4985                	li	s3,1
    80004fc0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fc4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fc8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fcc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fd0:	00003597          	auipc	a1,0x3
    80004fd4:	4d058593          	addi	a1,a1,1232 # 800084a0 <states.0+0x1b0>
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	d1a080e7          	jalr	-742(ra) # 80000cf2 <initlock>
  (*f0)->type = FD_PIPE;
    80004fe0:	609c                	ld	a5,0(s1)
    80004fe2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fe6:	609c                	ld	a5,0(s1)
    80004fe8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fec:	609c                	ld	a5,0(s1)
    80004fee:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ff2:	609c                	ld	a5,0(s1)
    80004ff4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ff8:	000a3783          	ld	a5,0(s4)
    80004ffc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005000:	000a3783          	ld	a5,0(s4)
    80005004:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005008:	000a3783          	ld	a5,0(s4)
    8000500c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005010:	000a3783          	ld	a5,0(s4)
    80005014:	0127b823          	sd	s2,16(a5)
  return 0;
    80005018:	4501                	li	a0,0
    8000501a:	a025                	j	80005042 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000501c:	6088                	ld	a0,0(s1)
    8000501e:	e501                	bnez	a0,80005026 <pipealloc+0xaa>
    80005020:	a039                	j	8000502e <pipealloc+0xb2>
    80005022:	6088                	ld	a0,0(s1)
    80005024:	c51d                	beqz	a0,80005052 <pipealloc+0xd6>
    fileclose(*f0);
    80005026:	00000097          	auipc	ra,0x0
    8000502a:	c26080e7          	jalr	-986(ra) # 80004c4c <fileclose>
  if(*f1)
    8000502e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005032:	557d                	li	a0,-1
  if(*f1)
    80005034:	c799                	beqz	a5,80005042 <pipealloc+0xc6>
    fileclose(*f1);
    80005036:	853e                	mv	a0,a5
    80005038:	00000097          	auipc	ra,0x0
    8000503c:	c14080e7          	jalr	-1004(ra) # 80004c4c <fileclose>
  return -1;
    80005040:	557d                	li	a0,-1
}
    80005042:	70a2                	ld	ra,40(sp)
    80005044:	7402                	ld	s0,32(sp)
    80005046:	64e2                	ld	s1,24(sp)
    80005048:	6942                	ld	s2,16(sp)
    8000504a:	69a2                	ld	s3,8(sp)
    8000504c:	6a02                	ld	s4,0(sp)
    8000504e:	6145                	addi	sp,sp,48
    80005050:	8082                	ret
  return -1;
    80005052:	557d                	li	a0,-1
    80005054:	b7fd                	j	80005042 <pipealloc+0xc6>

0000000080005056 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005056:	1101                	addi	sp,sp,-32
    80005058:	ec06                	sd	ra,24(sp)
    8000505a:	e822                	sd	s0,16(sp)
    8000505c:	e426                	sd	s1,8(sp)
    8000505e:	e04a                	sd	s2,0(sp)
    80005060:	1000                	addi	s0,sp,32
    80005062:	84aa                	mv	s1,a0
    80005064:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005066:	ffffc097          	auipc	ra,0xffffc
    8000506a:	d1c080e7          	jalr	-740(ra) # 80000d82 <acquire>
  if(writable){
    8000506e:	02090d63          	beqz	s2,800050a8 <pipeclose+0x52>
    pi->writeopen = 0;
    80005072:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005076:	21848513          	addi	a0,s1,536
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	3f2080e7          	jalr	1010(ra) # 8000246c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005082:	2204b783          	ld	a5,544(s1)
    80005086:	eb95                	bnez	a5,800050ba <pipeclose+0x64>
    release(&pi->lock);
    80005088:	8526                	mv	a0,s1
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	dac080e7          	jalr	-596(ra) # 80000e36 <release>
    kfree((char*)pi);
    80005092:	8526                	mv	a0,s1
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	a20080e7          	jalr	-1504(ra) # 80000ab4 <kfree>
  } else
    release(&pi->lock);
}
    8000509c:	60e2                	ld	ra,24(sp)
    8000509e:	6442                	ld	s0,16(sp)
    800050a0:	64a2                	ld	s1,8(sp)
    800050a2:	6902                	ld	s2,0(sp)
    800050a4:	6105                	addi	sp,sp,32
    800050a6:	8082                	ret
    pi->readopen = 0;
    800050a8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050ac:	21c48513          	addi	a0,s1,540
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	3bc080e7          	jalr	956(ra) # 8000246c <wakeup>
    800050b8:	b7e9                	j	80005082 <pipeclose+0x2c>
    release(&pi->lock);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	d7a080e7          	jalr	-646(ra) # 80000e36 <release>
}
    800050c4:	bfe1                	j	8000509c <pipeclose+0x46>

00000000800050c6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050c6:	711d                	addi	sp,sp,-96
    800050c8:	ec86                	sd	ra,88(sp)
    800050ca:	e8a2                	sd	s0,80(sp)
    800050cc:	e4a6                	sd	s1,72(sp)
    800050ce:	e0ca                	sd	s2,64(sp)
    800050d0:	fc4e                	sd	s3,56(sp)
    800050d2:	f852                	sd	s4,48(sp)
    800050d4:	f456                	sd	s5,40(sp)
    800050d6:	f05a                	sd	s6,32(sp)
    800050d8:	ec5e                	sd	s7,24(sp)
    800050da:	e862                	sd	s8,16(sp)
    800050dc:	1080                	addi	s0,sp,96
    800050de:	84aa                	mv	s1,a0
    800050e0:	8aae                	mv	s5,a1
    800050e2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	a9e080e7          	jalr	-1378(ra) # 80001b82 <myproc>
    800050ec:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050ee:	8526                	mv	a0,s1
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	c92080e7          	jalr	-878(ra) # 80000d82 <acquire>
  while(i < n){
    800050f8:	0b405663          	blez	s4,800051a4 <pipewrite+0xde>
  int i = 0;
    800050fc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050fe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005100:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005104:	21c48b93          	addi	s7,s1,540
    80005108:	a089                	j	8000514a <pipewrite+0x84>
      release(&pi->lock);
    8000510a:	8526                	mv	a0,s1
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	d2a080e7          	jalr	-726(ra) # 80000e36 <release>
      return -1;
    80005114:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005116:	854a                	mv	a0,s2
    80005118:	60e6                	ld	ra,88(sp)
    8000511a:	6446                	ld	s0,80(sp)
    8000511c:	64a6                	ld	s1,72(sp)
    8000511e:	6906                	ld	s2,64(sp)
    80005120:	79e2                	ld	s3,56(sp)
    80005122:	7a42                	ld	s4,48(sp)
    80005124:	7aa2                	ld	s5,40(sp)
    80005126:	7b02                	ld	s6,32(sp)
    80005128:	6be2                	ld	s7,24(sp)
    8000512a:	6c42                	ld	s8,16(sp)
    8000512c:	6125                	addi	sp,sp,96
    8000512e:	8082                	ret
      wakeup(&pi->nread);
    80005130:	8562                	mv	a0,s8
    80005132:	ffffd097          	auipc	ra,0xffffd
    80005136:	33a080e7          	jalr	826(ra) # 8000246c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000513a:	85a6                	mv	a1,s1
    8000513c:	855e                	mv	a0,s7
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	17e080e7          	jalr	382(ra) # 800022bc <sleep>
  while(i < n){
    80005146:	07495063          	bge	s2,s4,800051a6 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000514a:	2204a783          	lw	a5,544(s1)
    8000514e:	dfd5                	beqz	a5,8000510a <pipewrite+0x44>
    80005150:	854e                	mv	a0,s3
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	56a080e7          	jalr	1386(ra) # 800026bc <killed>
    8000515a:	f945                	bnez	a0,8000510a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000515c:	2184a783          	lw	a5,536(s1)
    80005160:	21c4a703          	lw	a4,540(s1)
    80005164:	2007879b          	addiw	a5,a5,512
    80005168:	fcf704e3          	beq	a4,a5,80005130 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000516c:	4685                	li	a3,1
    8000516e:	01590633          	add	a2,s2,s5
    80005172:	faf40593          	addi	a1,s0,-81
    80005176:	0509b503          	ld	a0,80(s3)
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	754080e7          	jalr	1876(ra) # 800018ce <copyin>
    80005182:	03650263          	beq	a0,s6,800051a6 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005186:	21c4a783          	lw	a5,540(s1)
    8000518a:	0017871b          	addiw	a4,a5,1
    8000518e:	20e4ae23          	sw	a4,540(s1)
    80005192:	1ff7f793          	andi	a5,a5,511
    80005196:	97a6                	add	a5,a5,s1
    80005198:	faf44703          	lbu	a4,-81(s0)
    8000519c:	00e78c23          	sb	a4,24(a5)
      i++;
    800051a0:	2905                	addiw	s2,s2,1
    800051a2:	b755                	j	80005146 <pipewrite+0x80>
  int i = 0;
    800051a4:	4901                	li	s2,0
  wakeup(&pi->nread);
    800051a6:	21848513          	addi	a0,s1,536
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	2c2080e7          	jalr	706(ra) # 8000246c <wakeup>
  release(&pi->lock);
    800051b2:	8526                	mv	a0,s1
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	c82080e7          	jalr	-894(ra) # 80000e36 <release>
  return i;
    800051bc:	bfa9                	j	80005116 <pipewrite+0x50>

00000000800051be <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051be:	715d                	addi	sp,sp,-80
    800051c0:	e486                	sd	ra,72(sp)
    800051c2:	e0a2                	sd	s0,64(sp)
    800051c4:	fc26                	sd	s1,56(sp)
    800051c6:	f84a                	sd	s2,48(sp)
    800051c8:	f44e                	sd	s3,40(sp)
    800051ca:	f052                	sd	s4,32(sp)
    800051cc:	ec56                	sd	s5,24(sp)
    800051ce:	e85a                	sd	s6,16(sp)
    800051d0:	0880                	addi	s0,sp,80
    800051d2:	84aa                	mv	s1,a0
    800051d4:	892e                	mv	s2,a1
    800051d6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	9aa080e7          	jalr	-1622(ra) # 80001b82 <myproc>
    800051e0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051e2:	8526                	mv	a0,s1
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	b9e080e7          	jalr	-1122(ra) # 80000d82 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051ec:	2184a703          	lw	a4,536(s1)
    800051f0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051f4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051f8:	02f71763          	bne	a4,a5,80005226 <piperead+0x68>
    800051fc:	2244a783          	lw	a5,548(s1)
    80005200:	c39d                	beqz	a5,80005226 <piperead+0x68>
    if(killed(pr)){
    80005202:	8552                	mv	a0,s4
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	4b8080e7          	jalr	1208(ra) # 800026bc <killed>
    8000520c:	e949                	bnez	a0,8000529e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000520e:	85a6                	mv	a1,s1
    80005210:	854e                	mv	a0,s3
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	0aa080e7          	jalr	170(ra) # 800022bc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000521a:	2184a703          	lw	a4,536(s1)
    8000521e:	21c4a783          	lw	a5,540(s1)
    80005222:	fcf70de3          	beq	a4,a5,800051fc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005226:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005228:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000522a:	05505463          	blez	s5,80005272 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000522e:	2184a783          	lw	a5,536(s1)
    80005232:	21c4a703          	lw	a4,540(s1)
    80005236:	02f70e63          	beq	a4,a5,80005272 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000523a:	0017871b          	addiw	a4,a5,1
    8000523e:	20e4ac23          	sw	a4,536(s1)
    80005242:	1ff7f793          	andi	a5,a5,511
    80005246:	97a6                	add	a5,a5,s1
    80005248:	0187c783          	lbu	a5,24(a5)
    8000524c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005250:	4685                	li	a3,1
    80005252:	fbf40613          	addi	a2,s0,-65
    80005256:	85ca                	mv	a1,s2
    80005258:	050a3503          	ld	a0,80(s4)
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	5b2080e7          	jalr	1458(ra) # 8000180e <copyout>
    80005264:	01650763          	beq	a0,s6,80005272 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005268:	2985                	addiw	s3,s3,1
    8000526a:	0905                	addi	s2,s2,1
    8000526c:	fd3a91e3          	bne	s5,s3,8000522e <piperead+0x70>
    80005270:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005272:	21c48513          	addi	a0,s1,540
    80005276:	ffffd097          	auipc	ra,0xffffd
    8000527a:	1f6080e7          	jalr	502(ra) # 8000246c <wakeup>
  release(&pi->lock);
    8000527e:	8526                	mv	a0,s1
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	bb6080e7          	jalr	-1098(ra) # 80000e36 <release>
  return i;
}
    80005288:	854e                	mv	a0,s3
    8000528a:	60a6                	ld	ra,72(sp)
    8000528c:	6406                	ld	s0,64(sp)
    8000528e:	74e2                	ld	s1,56(sp)
    80005290:	7942                	ld	s2,48(sp)
    80005292:	79a2                	ld	s3,40(sp)
    80005294:	7a02                	ld	s4,32(sp)
    80005296:	6ae2                	ld	s5,24(sp)
    80005298:	6b42                	ld	s6,16(sp)
    8000529a:	6161                	addi	sp,sp,80
    8000529c:	8082                	ret
      release(&pi->lock);
    8000529e:	8526                	mv	a0,s1
    800052a0:	ffffc097          	auipc	ra,0xffffc
    800052a4:	b96080e7          	jalr	-1130(ra) # 80000e36 <release>
      return -1;
    800052a8:	59fd                	li	s3,-1
    800052aa:	bff9                	j	80005288 <piperead+0xca>

00000000800052ac <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052ac:	1141                	addi	sp,sp,-16
    800052ae:	e422                	sd	s0,8(sp)
    800052b0:	0800                	addi	s0,sp,16
    800052b2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052b4:	8905                	andi	a0,a0,1
    800052b6:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800052b8:	8b89                	andi	a5,a5,2
    800052ba:	c399                	beqz	a5,800052c0 <flags2perm+0x14>
      perm |= PTE_W;
    800052bc:	00456513          	ori	a0,a0,4
    return perm;
}
    800052c0:	6422                	ld	s0,8(sp)
    800052c2:	0141                	addi	sp,sp,16
    800052c4:	8082                	ret

00000000800052c6 <exec>:

int
exec(char *path, char **argv)
{
    800052c6:	de010113          	addi	sp,sp,-544
    800052ca:	20113c23          	sd	ra,536(sp)
    800052ce:	20813823          	sd	s0,528(sp)
    800052d2:	20913423          	sd	s1,520(sp)
    800052d6:	21213023          	sd	s2,512(sp)
    800052da:	ffce                	sd	s3,504(sp)
    800052dc:	fbd2                	sd	s4,496(sp)
    800052de:	f7d6                	sd	s5,488(sp)
    800052e0:	f3da                	sd	s6,480(sp)
    800052e2:	efde                	sd	s7,472(sp)
    800052e4:	ebe2                	sd	s8,464(sp)
    800052e6:	e7e6                	sd	s9,456(sp)
    800052e8:	e3ea                	sd	s10,448(sp)
    800052ea:	ff6e                	sd	s11,440(sp)
    800052ec:	1400                	addi	s0,sp,544
    800052ee:	892a                	mv	s2,a0
    800052f0:	dea43423          	sd	a0,-536(s0)
    800052f4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052f8:	ffffd097          	auipc	ra,0xffffd
    800052fc:	88a080e7          	jalr	-1910(ra) # 80001b82 <myproc>
    80005300:	84aa                	mv	s1,a0

  begin_op();
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	482080e7          	jalr	1154(ra) # 80004784 <begin_op>

  if((ip = namei(path)) == 0){
    8000530a:	854a                	mv	a0,s2
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	258080e7          	jalr	600(ra) # 80004564 <namei>
    80005314:	c93d                	beqz	a0,8000538a <exec+0xc4>
    80005316:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	aa0080e7          	jalr	-1376(ra) # 80003db8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005320:	04000713          	li	a4,64
    80005324:	4681                	li	a3,0
    80005326:	e5040613          	addi	a2,s0,-432
    8000532a:	4581                	li	a1,0
    8000532c:	8556                	mv	a0,s5
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	d3e080e7          	jalr	-706(ra) # 8000406c <readi>
    80005336:	04000793          	li	a5,64
    8000533a:	00f51a63          	bne	a0,a5,8000534e <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000533e:	e5042703          	lw	a4,-432(s0)
    80005342:	464c47b7          	lui	a5,0x464c4
    80005346:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000534a:	04f70663          	beq	a4,a5,80005396 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000534e:	8556                	mv	a0,s5
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	cca080e7          	jalr	-822(ra) # 8000401a <iunlockput>
    end_op();
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	4aa080e7          	jalr	1194(ra) # 80004802 <end_op>
  }
  return -1;
    80005360:	557d                	li	a0,-1
}
    80005362:	21813083          	ld	ra,536(sp)
    80005366:	21013403          	ld	s0,528(sp)
    8000536a:	20813483          	ld	s1,520(sp)
    8000536e:	20013903          	ld	s2,512(sp)
    80005372:	79fe                	ld	s3,504(sp)
    80005374:	7a5e                	ld	s4,496(sp)
    80005376:	7abe                	ld	s5,488(sp)
    80005378:	7b1e                	ld	s6,480(sp)
    8000537a:	6bfe                	ld	s7,472(sp)
    8000537c:	6c5e                	ld	s8,464(sp)
    8000537e:	6cbe                	ld	s9,456(sp)
    80005380:	6d1e                	ld	s10,448(sp)
    80005382:	7dfa                	ld	s11,440(sp)
    80005384:	22010113          	addi	sp,sp,544
    80005388:	8082                	ret
    end_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	478080e7          	jalr	1144(ra) # 80004802 <end_op>
    return -1;
    80005392:	557d                	li	a0,-1
    80005394:	b7f9                	j	80005362 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005396:	8526                	mv	a0,s1
    80005398:	ffffd097          	auipc	ra,0xffffd
    8000539c:	8ae080e7          	jalr	-1874(ra) # 80001c46 <proc_pagetable>
    800053a0:	8b2a                	mv	s6,a0
    800053a2:	d555                	beqz	a0,8000534e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a4:	e7042783          	lw	a5,-400(s0)
    800053a8:	e8845703          	lhu	a4,-376(s0)
    800053ac:	c735                	beqz	a4,80005418 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053b0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800053b4:	6a05                	lui	s4,0x1
    800053b6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800053ba:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800053be:	6d85                	lui	s11,0x1
    800053c0:	7d7d                	lui	s10,0xfffff
    800053c2:	ac3d                	j	80005600 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053c4:	00003517          	auipc	a0,0x3
    800053c8:	63450513          	addi	a0,a0,1588 # 800089f8 <syscallnames+0x388>
    800053cc:	ffffb097          	auipc	ra,0xffffb
    800053d0:	174080e7          	jalr	372(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053d4:	874a                	mv	a4,s2
    800053d6:	009c86bb          	addw	a3,s9,s1
    800053da:	4581                	li	a1,0
    800053dc:	8556                	mv	a0,s5
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	c8e080e7          	jalr	-882(ra) # 8000406c <readi>
    800053e6:	2501                	sext.w	a0,a0
    800053e8:	1aa91963          	bne	s2,a0,8000559a <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800053ec:	009d84bb          	addw	s1,s11,s1
    800053f0:	013d09bb          	addw	s3,s10,s3
    800053f4:	1f74f663          	bgeu	s1,s7,800055e0 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800053f8:	02049593          	slli	a1,s1,0x20
    800053fc:	9181                	srli	a1,a1,0x20
    800053fe:	95e2                	add	a1,a1,s8
    80005400:	855a                	mv	a0,s6
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	e06080e7          	jalr	-506(ra) # 80001208 <walkaddr>
    8000540a:	862a                	mv	a2,a0
    if(pa == 0)
    8000540c:	dd45                	beqz	a0,800053c4 <exec+0xfe>
      n = PGSIZE;
    8000540e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005410:	fd49f2e3          	bgeu	s3,s4,800053d4 <exec+0x10e>
      n = sz - i;
    80005414:	894e                	mv	s2,s3
    80005416:	bf7d                	j	800053d4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005418:	4901                	li	s2,0
  iunlockput(ip);
    8000541a:	8556                	mv	a0,s5
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	bfe080e7          	jalr	-1026(ra) # 8000401a <iunlockput>
  end_op();
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	3de080e7          	jalr	990(ra) # 80004802 <end_op>
  p = myproc();
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	756080e7          	jalr	1878(ra) # 80001b82 <myproc>
    80005434:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005436:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000543a:	6785                	lui	a5,0x1
    8000543c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000543e:	97ca                	add	a5,a5,s2
    80005440:	777d                	lui	a4,0xfffff
    80005442:	8ff9                	and	a5,a5,a4
    80005444:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005448:	4691                	li	a3,4
    8000544a:	6609                	lui	a2,0x2
    8000544c:	963e                	add	a2,a2,a5
    8000544e:	85be                	mv	a1,a5
    80005450:	855a                	mv	a0,s6
    80005452:	ffffc097          	auipc	ra,0xffffc
    80005456:	16a080e7          	jalr	362(ra) # 800015bc <uvmalloc>
    8000545a:	8c2a                	mv	s8,a0
  ip = 0;
    8000545c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000545e:	12050e63          	beqz	a0,8000559a <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005462:	75f9                	lui	a1,0xffffe
    80005464:	95aa                	add	a1,a1,a0
    80005466:	855a                	mv	a0,s6
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	374080e7          	jalr	884(ra) # 800017dc <uvmclear>
  stackbase = sp - PGSIZE;
    80005470:	7afd                	lui	s5,0xfffff
    80005472:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005474:	df043783          	ld	a5,-528(s0)
    80005478:	6388                	ld	a0,0(a5)
    8000547a:	c925                	beqz	a0,800054ea <exec+0x224>
    8000547c:	e9040993          	addi	s3,s0,-368
    80005480:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005484:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005486:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	b72080e7          	jalr	-1166(ra) # 80000ffa <strlen>
    80005490:	0015079b          	addiw	a5,a0,1
    80005494:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005498:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000549c:	13596663          	bltu	s2,s5,800055c8 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054a0:	df043d83          	ld	s11,-528(s0)
    800054a4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800054a8:	8552                	mv	a0,s4
    800054aa:	ffffc097          	auipc	ra,0xffffc
    800054ae:	b50080e7          	jalr	-1200(ra) # 80000ffa <strlen>
    800054b2:	0015069b          	addiw	a3,a0,1
    800054b6:	8652                	mv	a2,s4
    800054b8:	85ca                	mv	a1,s2
    800054ba:	855a                	mv	a0,s6
    800054bc:	ffffc097          	auipc	ra,0xffffc
    800054c0:	352080e7          	jalr	850(ra) # 8000180e <copyout>
    800054c4:	10054663          	bltz	a0,800055d0 <exec+0x30a>
    ustack[argc] = sp;
    800054c8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054cc:	0485                	addi	s1,s1,1
    800054ce:	008d8793          	addi	a5,s11,8
    800054d2:	def43823          	sd	a5,-528(s0)
    800054d6:	008db503          	ld	a0,8(s11)
    800054da:	c911                	beqz	a0,800054ee <exec+0x228>
    if(argc >= MAXARG)
    800054dc:	09a1                	addi	s3,s3,8
    800054de:	fb3c95e3          	bne	s9,s3,80005488 <exec+0x1c2>
  sz = sz1;
    800054e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054e6:	4a81                	li	s5,0
    800054e8:	a84d                	j	8000559a <exec+0x2d4>
  sp = sz;
    800054ea:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054ec:	4481                	li	s1,0
  ustack[argc] = 0;
    800054ee:	00349793          	slli	a5,s1,0x3
    800054f2:	f9078793          	addi	a5,a5,-112
    800054f6:	97a2                	add	a5,a5,s0
    800054f8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800054fc:	00148693          	addi	a3,s1,1
    80005500:	068e                	slli	a3,a3,0x3
    80005502:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005506:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000550a:	01597663          	bgeu	s2,s5,80005516 <exec+0x250>
  sz = sz1;
    8000550e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005512:	4a81                	li	s5,0
    80005514:	a059                	j	8000559a <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005516:	e9040613          	addi	a2,s0,-368
    8000551a:	85ca                	mv	a1,s2
    8000551c:	855a                	mv	a0,s6
    8000551e:	ffffc097          	auipc	ra,0xffffc
    80005522:	2f0080e7          	jalr	752(ra) # 8000180e <copyout>
    80005526:	0a054963          	bltz	a0,800055d8 <exec+0x312>
  p->trapframe->a1 = sp;
    8000552a:	058bb783          	ld	a5,88(s7)
    8000552e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005532:	de843783          	ld	a5,-536(s0)
    80005536:	0007c703          	lbu	a4,0(a5)
    8000553a:	cf11                	beqz	a4,80005556 <exec+0x290>
    8000553c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000553e:	02f00693          	li	a3,47
    80005542:	a039                	j	80005550 <exec+0x28a>
      last = s+1;
    80005544:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005548:	0785                	addi	a5,a5,1
    8000554a:	fff7c703          	lbu	a4,-1(a5)
    8000554e:	c701                	beqz	a4,80005556 <exec+0x290>
    if(*s == '/')
    80005550:	fed71ce3          	bne	a4,a3,80005548 <exec+0x282>
    80005554:	bfc5                	j	80005544 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005556:	4641                	li	a2,16
    80005558:	de843583          	ld	a1,-536(s0)
    8000555c:	158b8513          	addi	a0,s7,344
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	a68080e7          	jalr	-1432(ra) # 80000fc8 <safestrcpy>
  oldpagetable = p->pagetable;
    80005568:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000556c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005570:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005574:	058bb783          	ld	a5,88(s7)
    80005578:	e6843703          	ld	a4,-408(s0)
    8000557c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000557e:	058bb783          	ld	a5,88(s7)
    80005582:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005586:	85ea                	mv	a1,s10
    80005588:	ffffc097          	auipc	ra,0xffffc
    8000558c:	75a080e7          	jalr	1882(ra) # 80001ce2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005590:	0004851b          	sext.w	a0,s1
    80005594:	b3f9                	j	80005362 <exec+0x9c>
    80005596:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000559a:	df843583          	ld	a1,-520(s0)
    8000559e:	855a                	mv	a0,s6
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	742080e7          	jalr	1858(ra) # 80001ce2 <proc_freepagetable>
  if(ip){
    800055a8:	da0a93e3          	bnez	s5,8000534e <exec+0x88>
  return -1;
    800055ac:	557d                	li	a0,-1
    800055ae:	bb55                	j	80005362 <exec+0x9c>
    800055b0:	df243c23          	sd	s2,-520(s0)
    800055b4:	b7dd                	j	8000559a <exec+0x2d4>
    800055b6:	df243c23          	sd	s2,-520(s0)
    800055ba:	b7c5                	j	8000559a <exec+0x2d4>
    800055bc:	df243c23          	sd	s2,-520(s0)
    800055c0:	bfe9                	j	8000559a <exec+0x2d4>
    800055c2:	df243c23          	sd	s2,-520(s0)
    800055c6:	bfd1                	j	8000559a <exec+0x2d4>
  sz = sz1;
    800055c8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055cc:	4a81                	li	s5,0
    800055ce:	b7f1                	j	8000559a <exec+0x2d4>
  sz = sz1;
    800055d0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055d4:	4a81                	li	s5,0
    800055d6:	b7d1                	j	8000559a <exec+0x2d4>
  sz = sz1;
    800055d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055dc:	4a81                	li	s5,0
    800055de:	bf75                	j	8000559a <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055e0:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055e4:	e0843783          	ld	a5,-504(s0)
    800055e8:	0017869b          	addiw	a3,a5,1
    800055ec:	e0d43423          	sd	a3,-504(s0)
    800055f0:	e0043783          	ld	a5,-512(s0)
    800055f4:	0387879b          	addiw	a5,a5,56
    800055f8:	e8845703          	lhu	a4,-376(s0)
    800055fc:	e0e6dfe3          	bge	a3,a4,8000541a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005600:	2781                	sext.w	a5,a5
    80005602:	e0f43023          	sd	a5,-512(s0)
    80005606:	03800713          	li	a4,56
    8000560a:	86be                	mv	a3,a5
    8000560c:	e1840613          	addi	a2,s0,-488
    80005610:	4581                	li	a1,0
    80005612:	8556                	mv	a0,s5
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	a58080e7          	jalr	-1448(ra) # 8000406c <readi>
    8000561c:	03800793          	li	a5,56
    80005620:	f6f51be3          	bne	a0,a5,80005596 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005624:	e1842783          	lw	a5,-488(s0)
    80005628:	4705                	li	a4,1
    8000562a:	fae79de3          	bne	a5,a4,800055e4 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000562e:	e4043483          	ld	s1,-448(s0)
    80005632:	e3843783          	ld	a5,-456(s0)
    80005636:	f6f4ede3          	bltu	s1,a5,800055b0 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000563a:	e2843783          	ld	a5,-472(s0)
    8000563e:	94be                	add	s1,s1,a5
    80005640:	f6f4ebe3          	bltu	s1,a5,800055b6 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005644:	de043703          	ld	a4,-544(s0)
    80005648:	8ff9                	and	a5,a5,a4
    8000564a:	fbad                	bnez	a5,800055bc <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000564c:	e1c42503          	lw	a0,-484(s0)
    80005650:	00000097          	auipc	ra,0x0
    80005654:	c5c080e7          	jalr	-932(ra) # 800052ac <flags2perm>
    80005658:	86aa                	mv	a3,a0
    8000565a:	8626                	mv	a2,s1
    8000565c:	85ca                	mv	a1,s2
    8000565e:	855a                	mv	a0,s6
    80005660:	ffffc097          	auipc	ra,0xffffc
    80005664:	f5c080e7          	jalr	-164(ra) # 800015bc <uvmalloc>
    80005668:	dea43c23          	sd	a0,-520(s0)
    8000566c:	d939                	beqz	a0,800055c2 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000566e:	e2843c03          	ld	s8,-472(s0)
    80005672:	e2042c83          	lw	s9,-480(s0)
    80005676:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000567a:	f60b83e3          	beqz	s7,800055e0 <exec+0x31a>
    8000567e:	89de                	mv	s3,s7
    80005680:	4481                	li	s1,0
    80005682:	bb9d                	j	800053f8 <exec+0x132>

0000000080005684 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005684:	7179                	addi	sp,sp,-48
    80005686:	f406                	sd	ra,40(sp)
    80005688:	f022                	sd	s0,32(sp)
    8000568a:	ec26                	sd	s1,24(sp)
    8000568c:	e84a                	sd	s2,16(sp)
    8000568e:	1800                	addi	s0,sp,48
    80005690:	892e                	mv	s2,a1
    80005692:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005694:	fdc40593          	addi	a1,s0,-36
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	93a080e7          	jalr	-1734(ra) # 80002fd2 <argint>
  if (fd < 0 || fd >= NOFILE || (f = myproc()->ofile[fd]) == 0)
    800056a0:	fdc42703          	lw	a4,-36(s0)
    800056a4:	47bd                	li	a5,15
    800056a6:	02e7eb63          	bltu	a5,a4,800056dc <argfd+0x58>
    800056aa:	ffffc097          	auipc	ra,0xffffc
    800056ae:	4d8080e7          	jalr	1240(ra) # 80001b82 <myproc>
    800056b2:	fdc42703          	lw	a4,-36(s0)
    800056b6:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbc18a>
    800056ba:	078e                	slli	a5,a5,0x3
    800056bc:	953e                	add	a0,a0,a5
    800056be:	611c                	ld	a5,0(a0)
    800056c0:	c385                	beqz	a5,800056e0 <argfd+0x5c>
    return -1;
  if (pfd)
    800056c2:	00090463          	beqz	s2,800056ca <argfd+0x46>
    *pfd = fd;
    800056c6:	00e92023          	sw	a4,0(s2)
  if (pf)
    *pf = f;
  return 0;
    800056ca:	4501                	li	a0,0
  if (pf)
    800056cc:	c091                	beqz	s1,800056d0 <argfd+0x4c>
    *pf = f;
    800056ce:	e09c                	sd	a5,0(s1)
}
    800056d0:	70a2                	ld	ra,40(sp)
    800056d2:	7402                	ld	s0,32(sp)
    800056d4:	64e2                	ld	s1,24(sp)
    800056d6:	6942                	ld	s2,16(sp)
    800056d8:	6145                	addi	sp,sp,48
    800056da:	8082                	ret
    return -1;
    800056dc:	557d                	li	a0,-1
    800056de:	bfcd                	j	800056d0 <argfd+0x4c>
    800056e0:	557d                	li	a0,-1
    800056e2:	b7fd                	j	800056d0 <argfd+0x4c>

00000000800056e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056e4:	1101                	addi	sp,sp,-32
    800056e6:	ec06                	sd	ra,24(sp)
    800056e8:	e822                	sd	s0,16(sp)
    800056ea:	e426                	sd	s1,8(sp)
    800056ec:	1000                	addi	s0,sp,32
    800056ee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056f0:	ffffc097          	auipc	ra,0xffffc
    800056f4:	492080e7          	jalr	1170(ra) # 80001b82 <myproc>
    800056f8:	862a                	mv	a2,a0

  for (fd = 0; fd < NOFILE; fd++)
    800056fa:	0d050793          	addi	a5,a0,208
    800056fe:	4501                	li	a0,0
    80005700:	46c1                	li	a3,16
  {
    if (p->ofile[fd] == 0)
    80005702:	6398                	ld	a4,0(a5)
    80005704:	cb19                	beqz	a4,8000571a <fdalloc+0x36>
  for (fd = 0; fd < NOFILE; fd++)
    80005706:	2505                	addiw	a0,a0,1
    80005708:	07a1                	addi	a5,a5,8
    8000570a:	fed51ce3          	bne	a0,a3,80005702 <fdalloc+0x1e>
    {
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000570e:	557d                	li	a0,-1
}
    80005710:	60e2                	ld	ra,24(sp)
    80005712:	6442                	ld	s0,16(sp)
    80005714:	64a2                	ld	s1,8(sp)
    80005716:	6105                	addi	sp,sp,32
    80005718:	8082                	ret
      p->ofile[fd] = f;
    8000571a:	01a50793          	addi	a5,a0,26
    8000571e:	078e                	slli	a5,a5,0x3
    80005720:	963e                	add	a2,a2,a5
    80005722:	e204                	sd	s1,0(a2)
      return fd;
    80005724:	b7f5                	j	80005710 <fdalloc+0x2c>

0000000080005726 <create>:
  return -1;
}

static struct inode *
create(char *path, short type, short major, short minor)
{
    80005726:	715d                	addi	sp,sp,-80
    80005728:	e486                	sd	ra,72(sp)
    8000572a:	e0a2                	sd	s0,64(sp)
    8000572c:	fc26                	sd	s1,56(sp)
    8000572e:	f84a                	sd	s2,48(sp)
    80005730:	f44e                	sd	s3,40(sp)
    80005732:	f052                	sd	s4,32(sp)
    80005734:	ec56                	sd	s5,24(sp)
    80005736:	e85a                	sd	s6,16(sp)
    80005738:	0880                	addi	s0,sp,80
    8000573a:	8b2e                	mv	s6,a1
    8000573c:	89b2                	mv	s3,a2
    8000573e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if ((dp = nameiparent(path, name)) == 0)
    80005740:	fb040593          	addi	a1,s0,-80
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	e3e080e7          	jalr	-450(ra) # 80004582 <nameiparent>
    8000574c:	84aa                	mv	s1,a0
    8000574e:	14050f63          	beqz	a0,800058ac <create+0x186>
    return 0;

  ilock(dp);
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	666080e7          	jalr	1638(ra) # 80003db8 <ilock>

  if ((ip = dirlookup(dp, name, 0)) != 0)
    8000575a:	4601                	li	a2,0
    8000575c:	fb040593          	addi	a1,s0,-80
    80005760:	8526                	mv	a0,s1
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	b3a080e7          	jalr	-1222(ra) # 8000429c <dirlookup>
    8000576a:	8aaa                	mv	s5,a0
    8000576c:	c931                	beqz	a0,800057c0 <create+0x9a>
  {
    iunlockput(dp);
    8000576e:	8526                	mv	a0,s1
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	8aa080e7          	jalr	-1878(ra) # 8000401a <iunlockput>
    ilock(ip);
    80005778:	8556                	mv	a0,s5
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	63e080e7          	jalr	1598(ra) # 80003db8 <ilock>
    if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005782:	000b059b          	sext.w	a1,s6
    80005786:	4789                	li	a5,2
    80005788:	02f59563          	bne	a1,a5,800057b2 <create+0x8c>
    8000578c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbc1b4>
    80005790:	37f9                	addiw	a5,a5,-2
    80005792:	17c2                	slli	a5,a5,0x30
    80005794:	93c1                	srli	a5,a5,0x30
    80005796:	4705                	li	a4,1
    80005798:	00f76d63          	bltu	a4,a5,800057b2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000579c:	8556                	mv	a0,s5
    8000579e:	60a6                	ld	ra,72(sp)
    800057a0:	6406                	ld	s0,64(sp)
    800057a2:	74e2                	ld	s1,56(sp)
    800057a4:	7942                	ld	s2,48(sp)
    800057a6:	79a2                	ld	s3,40(sp)
    800057a8:	7a02                	ld	s4,32(sp)
    800057aa:	6ae2                	ld	s5,24(sp)
    800057ac:	6b42                	ld	s6,16(sp)
    800057ae:	6161                	addi	sp,sp,80
    800057b0:	8082                	ret
    iunlockput(ip);
    800057b2:	8556                	mv	a0,s5
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	866080e7          	jalr	-1946(ra) # 8000401a <iunlockput>
    return 0;
    800057bc:	4a81                	li	s5,0
    800057be:	bff9                	j	8000579c <create+0x76>
  if ((ip = ialloc(dp->dev, type)) == 0)
    800057c0:	85da                	mv	a1,s6
    800057c2:	4088                	lw	a0,0(s1)
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	456080e7          	jalr	1110(ra) # 80003c1a <ialloc>
    800057cc:	8a2a                	mv	s4,a0
    800057ce:	c539                	beqz	a0,8000581c <create+0xf6>
  ilock(ip);
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	5e8080e7          	jalr	1512(ra) # 80003db8 <ilock>
  ip->major = major;
    800057d8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057dc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057e0:	4905                	li	s2,1
    800057e2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057e6:	8552                	mv	a0,s4
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	504080e7          	jalr	1284(ra) # 80003cec <iupdate>
  if (type == T_DIR)
    800057f0:	000b059b          	sext.w	a1,s6
    800057f4:	03258b63          	beq	a1,s2,8000582a <create+0x104>
  if (dirlink(dp, name, ip->inum) < 0)
    800057f8:	004a2603          	lw	a2,4(s4)
    800057fc:	fb040593          	addi	a1,s0,-80
    80005800:	8526                	mv	a0,s1
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	cb0080e7          	jalr	-848(ra) # 800044b2 <dirlink>
    8000580a:	06054f63          	bltz	a0,80005888 <create+0x162>
  iunlockput(dp);
    8000580e:	8526                	mv	a0,s1
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	80a080e7          	jalr	-2038(ra) # 8000401a <iunlockput>
  return ip;
    80005818:	8ad2                	mv	s5,s4
    8000581a:	b749                	j	8000579c <create+0x76>
    iunlockput(dp);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	7fc080e7          	jalr	2044(ra) # 8000401a <iunlockput>
    return 0;
    80005826:	8ad2                	mv	s5,s4
    80005828:	bf95                	j	8000579c <create+0x76>
    if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000582a:	004a2603          	lw	a2,4(s4)
    8000582e:	00003597          	auipc	a1,0x3
    80005832:	1ea58593          	addi	a1,a1,490 # 80008a18 <syscallnames+0x3a8>
    80005836:	8552                	mv	a0,s4
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	c7a080e7          	jalr	-902(ra) # 800044b2 <dirlink>
    80005840:	04054463          	bltz	a0,80005888 <create+0x162>
    80005844:	40d0                	lw	a2,4(s1)
    80005846:	00003597          	auipc	a1,0x3
    8000584a:	1da58593          	addi	a1,a1,474 # 80008a20 <syscallnames+0x3b0>
    8000584e:	8552                	mv	a0,s4
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	c62080e7          	jalr	-926(ra) # 800044b2 <dirlink>
    80005858:	02054863          	bltz	a0,80005888 <create+0x162>
  if (dirlink(dp, name, ip->inum) < 0)
    8000585c:	004a2603          	lw	a2,4(s4)
    80005860:	fb040593          	addi	a1,s0,-80
    80005864:	8526                	mv	a0,s1
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	c4c080e7          	jalr	-948(ra) # 800044b2 <dirlink>
    8000586e:	00054d63          	bltz	a0,80005888 <create+0x162>
    dp->nlink++; // for ".."
    80005872:	04a4d783          	lhu	a5,74(s1)
    80005876:	2785                	addiw	a5,a5,1
    80005878:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	46e080e7          	jalr	1134(ra) # 80003cec <iupdate>
    80005886:	b761                	j	8000580e <create+0xe8>
  ip->nlink = 0;
    80005888:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000588c:	8552                	mv	a0,s4
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	45e080e7          	jalr	1118(ra) # 80003cec <iupdate>
  iunlockput(ip);
    80005896:	8552                	mv	a0,s4
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	782080e7          	jalr	1922(ra) # 8000401a <iunlockput>
  iunlockput(dp);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	778080e7          	jalr	1912(ra) # 8000401a <iunlockput>
  return 0;
    800058aa:	bdcd                	j	8000579c <create+0x76>
    return 0;
    800058ac:	8aaa                	mv	s5,a0
    800058ae:	b5fd                	j	8000579c <create+0x76>

00000000800058b0 <sys_dup>:
{
    800058b0:	7179                	addi	sp,sp,-48
    800058b2:	f406                	sd	ra,40(sp)
    800058b4:	f022                	sd	s0,32(sp)
    800058b6:	ec26                	sd	s1,24(sp)
    800058b8:	e84a                	sd	s2,16(sp)
    800058ba:	1800                	addi	s0,sp,48
  if (argfd(0, 0, &f) < 0)
    800058bc:	fd840613          	addi	a2,s0,-40
    800058c0:	4581                	li	a1,0
    800058c2:	4501                	li	a0,0
    800058c4:	00000097          	auipc	ra,0x0
    800058c8:	dc0080e7          	jalr	-576(ra) # 80005684 <argfd>
    return -1;
    800058cc:	57fd                	li	a5,-1
  if (argfd(0, 0, &f) < 0)
    800058ce:	02054363          	bltz	a0,800058f4 <sys_dup+0x44>
  if ((fd = fdalloc(f)) < 0)
    800058d2:	fd843903          	ld	s2,-40(s0)
    800058d6:	854a                	mv	a0,s2
    800058d8:	00000097          	auipc	ra,0x0
    800058dc:	e0c080e7          	jalr	-500(ra) # 800056e4 <fdalloc>
    800058e0:	84aa                	mv	s1,a0
    return -1;
    800058e2:	57fd                	li	a5,-1
  if ((fd = fdalloc(f)) < 0)
    800058e4:	00054863          	bltz	a0,800058f4 <sys_dup+0x44>
  filedup(f);
    800058e8:	854a                	mv	a0,s2
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	310080e7          	jalr	784(ra) # 80004bfa <filedup>
  return fd;
    800058f2:	87a6                	mv	a5,s1
}
    800058f4:	853e                	mv	a0,a5
    800058f6:	70a2                	ld	ra,40(sp)
    800058f8:	7402                	ld	s0,32(sp)
    800058fa:	64e2                	ld	s1,24(sp)
    800058fc:	6942                	ld	s2,16(sp)
    800058fe:	6145                	addi	sp,sp,48
    80005900:	8082                	ret

0000000080005902 <sys_read>:
{
    80005902:	7179                	addi	sp,sp,-48
    80005904:	f406                	sd	ra,40(sp)
    80005906:	f022                	sd	s0,32(sp)
    80005908:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000590a:	fd840593          	addi	a1,s0,-40
    8000590e:	4505                	li	a0,1
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	6e2080e7          	jalr	1762(ra) # 80002ff2 <argaddr>
  argint(2, &n);
    80005918:	fe440593          	addi	a1,s0,-28
    8000591c:	4509                	li	a0,2
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	6b4080e7          	jalr	1716(ra) # 80002fd2 <argint>
  if (argfd(0, 0, &f) < 0)
    80005926:	fe840613          	addi	a2,s0,-24
    8000592a:	4581                	li	a1,0
    8000592c:	4501                	li	a0,0
    8000592e:	00000097          	auipc	ra,0x0
    80005932:	d56080e7          	jalr	-682(ra) # 80005684 <argfd>
    80005936:	87aa                	mv	a5,a0
    return -1;
    80005938:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0)
    8000593a:	0007cc63          	bltz	a5,80005952 <sys_read+0x50>
  return fileread(f, p, n);
    8000593e:	fe442603          	lw	a2,-28(s0)
    80005942:	fd843583          	ld	a1,-40(s0)
    80005946:	fe843503          	ld	a0,-24(s0)
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	43c080e7          	jalr	1084(ra) # 80004d86 <fileread>
}
    80005952:	70a2                	ld	ra,40(sp)
    80005954:	7402                	ld	s0,32(sp)
    80005956:	6145                	addi	sp,sp,48
    80005958:	8082                	ret

000000008000595a <sys_write>:
{
    8000595a:	7179                	addi	sp,sp,-48
    8000595c:	f406                	sd	ra,40(sp)
    8000595e:	f022                	sd	s0,32(sp)
    80005960:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005962:	fd840593          	addi	a1,s0,-40
    80005966:	4505                	li	a0,1
    80005968:	ffffd097          	auipc	ra,0xffffd
    8000596c:	68a080e7          	jalr	1674(ra) # 80002ff2 <argaddr>
  argint(2, &n);
    80005970:	fe440593          	addi	a1,s0,-28
    80005974:	4509                	li	a0,2
    80005976:	ffffd097          	auipc	ra,0xffffd
    8000597a:	65c080e7          	jalr	1628(ra) # 80002fd2 <argint>
  if (argfd(0, 0, &f) < 0)
    8000597e:	fe840613          	addi	a2,s0,-24
    80005982:	4581                	li	a1,0
    80005984:	4501                	li	a0,0
    80005986:	00000097          	auipc	ra,0x0
    8000598a:	cfe080e7          	jalr	-770(ra) # 80005684 <argfd>
    8000598e:	87aa                	mv	a5,a0
    return -1;
    80005990:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0)
    80005992:	0007cc63          	bltz	a5,800059aa <sys_write+0x50>
  return filewrite(f, p, n);
    80005996:	fe442603          	lw	a2,-28(s0)
    8000599a:	fd843583          	ld	a1,-40(s0)
    8000599e:	fe843503          	ld	a0,-24(s0)
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	4a6080e7          	jalr	1190(ra) # 80004e48 <filewrite>
}
    800059aa:	70a2                	ld	ra,40(sp)
    800059ac:	7402                	ld	s0,32(sp)
    800059ae:	6145                	addi	sp,sp,48
    800059b0:	8082                	ret

00000000800059b2 <sys_close>:
{
    800059b2:	1101                	addi	sp,sp,-32
    800059b4:	ec06                	sd	ra,24(sp)
    800059b6:	e822                	sd	s0,16(sp)
    800059b8:	1000                	addi	s0,sp,32
  if (argfd(0, &fd, &f) < 0)
    800059ba:	fe040613          	addi	a2,s0,-32
    800059be:	fec40593          	addi	a1,s0,-20
    800059c2:	4501                	li	a0,0
    800059c4:	00000097          	auipc	ra,0x0
    800059c8:	cc0080e7          	jalr	-832(ra) # 80005684 <argfd>
    return -1;
    800059cc:	57fd                	li	a5,-1
  if (argfd(0, &fd, &f) < 0)
    800059ce:	02054463          	bltz	a0,800059f6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059d2:	ffffc097          	auipc	ra,0xffffc
    800059d6:	1b0080e7          	jalr	432(ra) # 80001b82 <myproc>
    800059da:	fec42783          	lw	a5,-20(s0)
    800059de:	07e9                	addi	a5,a5,26
    800059e0:	078e                	slli	a5,a5,0x3
    800059e2:	953e                	add	a0,a0,a5
    800059e4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800059e8:	fe043503          	ld	a0,-32(s0)
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	260080e7          	jalr	608(ra) # 80004c4c <fileclose>
  return 0;
    800059f4:	4781                	li	a5,0
}
    800059f6:	853e                	mv	a0,a5
    800059f8:	60e2                	ld	ra,24(sp)
    800059fa:	6442                	ld	s0,16(sp)
    800059fc:	6105                	addi	sp,sp,32
    800059fe:	8082                	ret

0000000080005a00 <sys_fstat>:
{
    80005a00:	1101                	addi	sp,sp,-32
    80005a02:	ec06                	sd	ra,24(sp)
    80005a04:	e822                	sd	s0,16(sp)
    80005a06:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005a08:	fe040593          	addi	a1,s0,-32
    80005a0c:	4505                	li	a0,1
    80005a0e:	ffffd097          	auipc	ra,0xffffd
    80005a12:	5e4080e7          	jalr	1508(ra) # 80002ff2 <argaddr>
  if (argfd(0, 0, &f) < 0)
    80005a16:	fe840613          	addi	a2,s0,-24
    80005a1a:	4581                	li	a1,0
    80005a1c:	4501                	li	a0,0
    80005a1e:	00000097          	auipc	ra,0x0
    80005a22:	c66080e7          	jalr	-922(ra) # 80005684 <argfd>
    80005a26:	87aa                	mv	a5,a0
    return -1;
    80005a28:	557d                	li	a0,-1
  if (argfd(0, 0, &f) < 0)
    80005a2a:	0007ca63          	bltz	a5,80005a3e <sys_fstat+0x3e>
  return filestat(f, st);
    80005a2e:	fe043583          	ld	a1,-32(s0)
    80005a32:	fe843503          	ld	a0,-24(s0)
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	2de080e7          	jalr	734(ra) # 80004d14 <filestat>
}
    80005a3e:	60e2                	ld	ra,24(sp)
    80005a40:	6442                	ld	s0,16(sp)
    80005a42:	6105                	addi	sp,sp,32
    80005a44:	8082                	ret

0000000080005a46 <sys_link>:
{
    80005a46:	7169                	addi	sp,sp,-304
    80005a48:	f606                	sd	ra,296(sp)
    80005a4a:	f222                	sd	s0,288(sp)
    80005a4c:	ee26                	sd	s1,280(sp)
    80005a4e:	ea4a                	sd	s2,272(sp)
    80005a50:	1a00                	addi	s0,sp,304
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a52:	08000613          	li	a2,128
    80005a56:	ed040593          	addi	a1,s0,-304
    80005a5a:	4501                	li	a0,0
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	5b6080e7          	jalr	1462(ra) # 80003012 <argstr>
    return -1;
    80005a64:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a66:	10054e63          	bltz	a0,80005b82 <sys_link+0x13c>
    80005a6a:	08000613          	li	a2,128
    80005a6e:	f5040593          	addi	a1,s0,-176
    80005a72:	4505                	li	a0,1
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	59e080e7          	jalr	1438(ra) # 80003012 <argstr>
    return -1;
    80005a7c:	57fd                	li	a5,-1
  if (argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a7e:	10054263          	bltz	a0,80005b82 <sys_link+0x13c>
  begin_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	d02080e7          	jalr	-766(ra) # 80004784 <begin_op>
  if ((ip = namei(old)) == 0)
    80005a8a:	ed040513          	addi	a0,s0,-304
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	ad6080e7          	jalr	-1322(ra) # 80004564 <namei>
    80005a96:	84aa                	mv	s1,a0
    80005a98:	c551                	beqz	a0,80005b24 <sys_link+0xde>
  ilock(ip);
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	31e080e7          	jalr	798(ra) # 80003db8 <ilock>
  if (ip->type == T_DIR)
    80005aa2:	04449703          	lh	a4,68(s1)
    80005aa6:	4785                	li	a5,1
    80005aa8:	08f70463          	beq	a4,a5,80005b30 <sys_link+0xea>
  ip->nlink++;
    80005aac:	04a4d783          	lhu	a5,74(s1)
    80005ab0:	2785                	addiw	a5,a5,1
    80005ab2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ab6:	8526                	mv	a0,s1
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	234080e7          	jalr	564(ra) # 80003cec <iupdate>
  iunlock(ip);
    80005ac0:	8526                	mv	a0,s1
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	3b8080e7          	jalr	952(ra) # 80003e7a <iunlock>
  if ((dp = nameiparent(new, name)) == 0)
    80005aca:	fd040593          	addi	a1,s0,-48
    80005ace:	f5040513          	addi	a0,s0,-176
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	ab0080e7          	jalr	-1360(ra) # 80004582 <nameiparent>
    80005ada:	892a                	mv	s2,a0
    80005adc:	c935                	beqz	a0,80005b50 <sys_link+0x10a>
  ilock(dp);
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	2da080e7          	jalr	730(ra) # 80003db8 <ilock>
  if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0)
    80005ae6:	00092703          	lw	a4,0(s2)
    80005aea:	409c                	lw	a5,0(s1)
    80005aec:	04f71d63          	bne	a4,a5,80005b46 <sys_link+0x100>
    80005af0:	40d0                	lw	a2,4(s1)
    80005af2:	fd040593          	addi	a1,s0,-48
    80005af6:	854a                	mv	a0,s2
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	9ba080e7          	jalr	-1606(ra) # 800044b2 <dirlink>
    80005b00:	04054363          	bltz	a0,80005b46 <sys_link+0x100>
  iunlockput(dp);
    80005b04:	854a                	mv	a0,s2
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	514080e7          	jalr	1300(ra) # 8000401a <iunlockput>
  iput(ip);
    80005b0e:	8526                	mv	a0,s1
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	462080e7          	jalr	1122(ra) # 80003f72 <iput>
  end_op();
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	cea080e7          	jalr	-790(ra) # 80004802 <end_op>
  return 0;
    80005b20:	4781                	li	a5,0
    80005b22:	a085                	j	80005b82 <sys_link+0x13c>
    end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	cde080e7          	jalr	-802(ra) # 80004802 <end_op>
    return -1;
    80005b2c:	57fd                	li	a5,-1
    80005b2e:	a891                	j	80005b82 <sys_link+0x13c>
    iunlockput(ip);
    80005b30:	8526                	mv	a0,s1
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	4e8080e7          	jalr	1256(ra) # 8000401a <iunlockput>
    end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	cc8080e7          	jalr	-824(ra) # 80004802 <end_op>
    return -1;
    80005b42:	57fd                	li	a5,-1
    80005b44:	a83d                	j	80005b82 <sys_link+0x13c>
    iunlockput(dp);
    80005b46:	854a                	mv	a0,s2
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	4d2080e7          	jalr	1234(ra) # 8000401a <iunlockput>
  ilock(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	266080e7          	jalr	614(ra) # 80003db8 <ilock>
  ip->nlink--;
    80005b5a:	04a4d783          	lhu	a5,74(s1)
    80005b5e:	37fd                	addiw	a5,a5,-1
    80005b60:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b64:	8526                	mv	a0,s1
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	186080e7          	jalr	390(ra) # 80003cec <iupdate>
  iunlockput(ip);
    80005b6e:	8526                	mv	a0,s1
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	4aa080e7          	jalr	1194(ra) # 8000401a <iunlockput>
  end_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	c8a080e7          	jalr	-886(ra) # 80004802 <end_op>
  return -1;
    80005b80:	57fd                	li	a5,-1
}
    80005b82:	853e                	mv	a0,a5
    80005b84:	70b2                	ld	ra,296(sp)
    80005b86:	7412                	ld	s0,288(sp)
    80005b88:	64f2                	ld	s1,280(sp)
    80005b8a:	6952                	ld	s2,272(sp)
    80005b8c:	6155                	addi	sp,sp,304
    80005b8e:	8082                	ret

0000000080005b90 <sys_unlink>:
{
    80005b90:	7151                	addi	sp,sp,-240
    80005b92:	f586                	sd	ra,232(sp)
    80005b94:	f1a2                	sd	s0,224(sp)
    80005b96:	eda6                	sd	s1,216(sp)
    80005b98:	e9ca                	sd	s2,208(sp)
    80005b9a:	e5ce                	sd	s3,200(sp)
    80005b9c:	1980                	addi	s0,sp,240
  if (argstr(0, path, MAXPATH) < 0)
    80005b9e:	08000613          	li	a2,128
    80005ba2:	f3040593          	addi	a1,s0,-208
    80005ba6:	4501                	li	a0,0
    80005ba8:	ffffd097          	auipc	ra,0xffffd
    80005bac:	46a080e7          	jalr	1130(ra) # 80003012 <argstr>
    80005bb0:	18054163          	bltz	a0,80005d32 <sys_unlink+0x1a2>
  begin_op();
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	bd0080e7          	jalr	-1072(ra) # 80004784 <begin_op>
  if ((dp = nameiparent(path, name)) == 0)
    80005bbc:	fb040593          	addi	a1,s0,-80
    80005bc0:	f3040513          	addi	a0,s0,-208
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	9be080e7          	jalr	-1602(ra) # 80004582 <nameiparent>
    80005bcc:	84aa                	mv	s1,a0
    80005bce:	c979                	beqz	a0,80005ca4 <sys_unlink+0x114>
  ilock(dp);
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	1e8080e7          	jalr	488(ra) # 80003db8 <ilock>
  if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bd8:	00003597          	auipc	a1,0x3
    80005bdc:	e4058593          	addi	a1,a1,-448 # 80008a18 <syscallnames+0x3a8>
    80005be0:	fb040513          	addi	a0,s0,-80
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	69e080e7          	jalr	1694(ra) # 80004282 <namecmp>
    80005bec:	14050a63          	beqz	a0,80005d40 <sys_unlink+0x1b0>
    80005bf0:	00003597          	auipc	a1,0x3
    80005bf4:	e3058593          	addi	a1,a1,-464 # 80008a20 <syscallnames+0x3b0>
    80005bf8:	fb040513          	addi	a0,s0,-80
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	686080e7          	jalr	1670(ra) # 80004282 <namecmp>
    80005c04:	12050e63          	beqz	a0,80005d40 <sys_unlink+0x1b0>
  if ((ip = dirlookup(dp, name, &off)) == 0)
    80005c08:	f2c40613          	addi	a2,s0,-212
    80005c0c:	fb040593          	addi	a1,s0,-80
    80005c10:	8526                	mv	a0,s1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	68a080e7          	jalr	1674(ra) # 8000429c <dirlookup>
    80005c1a:	892a                	mv	s2,a0
    80005c1c:	12050263          	beqz	a0,80005d40 <sys_unlink+0x1b0>
  ilock(ip);
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	198080e7          	jalr	408(ra) # 80003db8 <ilock>
  if (ip->nlink < 1)
    80005c28:	04a91783          	lh	a5,74(s2)
    80005c2c:	08f05263          	blez	a5,80005cb0 <sys_unlink+0x120>
  if (ip->type == T_DIR && !isdirempty(ip))
    80005c30:	04491703          	lh	a4,68(s2)
    80005c34:	4785                	li	a5,1
    80005c36:	08f70563          	beq	a4,a5,80005cc0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c3a:	4641                	li	a2,16
    80005c3c:	4581                	li	a1,0
    80005c3e:	fc040513          	addi	a0,s0,-64
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	23c080e7          	jalr	572(ra) # 80000e7e <memset>
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c4a:	4741                	li	a4,16
    80005c4c:	f2c42683          	lw	a3,-212(s0)
    80005c50:	fc040613          	addi	a2,s0,-64
    80005c54:	4581                	li	a1,0
    80005c56:	8526                	mv	a0,s1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	50c080e7          	jalr	1292(ra) # 80004164 <writei>
    80005c60:	47c1                	li	a5,16
    80005c62:	0af51563          	bne	a0,a5,80005d0c <sys_unlink+0x17c>
  if (ip->type == T_DIR)
    80005c66:	04491703          	lh	a4,68(s2)
    80005c6a:	4785                	li	a5,1
    80005c6c:	0af70863          	beq	a4,a5,80005d1c <sys_unlink+0x18c>
  iunlockput(dp);
    80005c70:	8526                	mv	a0,s1
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	3a8080e7          	jalr	936(ra) # 8000401a <iunlockput>
  ip->nlink--;
    80005c7a:	04a95783          	lhu	a5,74(s2)
    80005c7e:	37fd                	addiw	a5,a5,-1
    80005c80:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c84:	854a                	mv	a0,s2
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	066080e7          	jalr	102(ra) # 80003cec <iupdate>
  iunlockput(ip);
    80005c8e:	854a                	mv	a0,s2
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	38a080e7          	jalr	906(ra) # 8000401a <iunlockput>
  end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	b6a080e7          	jalr	-1174(ra) # 80004802 <end_op>
  return 0;
    80005ca0:	4501                	li	a0,0
    80005ca2:	a84d                	j	80005d54 <sys_unlink+0x1c4>
    end_op();
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	b5e080e7          	jalr	-1186(ra) # 80004802 <end_op>
    return -1;
    80005cac:	557d                	li	a0,-1
    80005cae:	a05d                	j	80005d54 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cb0:	00003517          	auipc	a0,0x3
    80005cb4:	d7850513          	addi	a0,a0,-648 # 80008a28 <syscallnames+0x3b8>
    80005cb8:	ffffb097          	auipc	ra,0xffffb
    80005cbc:	888080e7          	jalr	-1912(ra) # 80000540 <panic>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005cc0:	04c92703          	lw	a4,76(s2)
    80005cc4:	02000793          	li	a5,32
    80005cc8:	f6e7f9e3          	bgeu	a5,a4,80005c3a <sys_unlink+0xaa>
    80005ccc:	02000993          	li	s3,32
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cd0:	4741                	li	a4,16
    80005cd2:	86ce                	mv	a3,s3
    80005cd4:	f1840613          	addi	a2,s0,-232
    80005cd8:	4581                	li	a1,0
    80005cda:	854a                	mv	a0,s2
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	390080e7          	jalr	912(ra) # 8000406c <readi>
    80005ce4:	47c1                	li	a5,16
    80005ce6:	00f51b63          	bne	a0,a5,80005cfc <sys_unlink+0x16c>
    if (de.inum != 0)
    80005cea:	f1845783          	lhu	a5,-232(s0)
    80005cee:	e7a1                	bnez	a5,80005d36 <sys_unlink+0x1a6>
  for (off = 2 * sizeof(de); off < dp->size; off += sizeof(de))
    80005cf0:	29c1                	addiw	s3,s3,16
    80005cf2:	04c92783          	lw	a5,76(s2)
    80005cf6:	fcf9ede3          	bltu	s3,a5,80005cd0 <sys_unlink+0x140>
    80005cfa:	b781                	j	80005c3a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cfc:	00003517          	auipc	a0,0x3
    80005d00:	d4450513          	addi	a0,a0,-700 # 80008a40 <syscallnames+0x3d0>
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	83c080e7          	jalr	-1988(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005d0c:	00003517          	auipc	a0,0x3
    80005d10:	d4c50513          	addi	a0,a0,-692 # 80008a58 <syscallnames+0x3e8>
    80005d14:	ffffb097          	auipc	ra,0xffffb
    80005d18:	82c080e7          	jalr	-2004(ra) # 80000540 <panic>
    dp->nlink--;
    80005d1c:	04a4d783          	lhu	a5,74(s1)
    80005d20:	37fd                	addiw	a5,a5,-1
    80005d22:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d26:	8526                	mv	a0,s1
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	fc4080e7          	jalr	-60(ra) # 80003cec <iupdate>
    80005d30:	b781                	j	80005c70 <sys_unlink+0xe0>
    return -1;
    80005d32:	557d                	li	a0,-1
    80005d34:	a005                	j	80005d54 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d36:	854a                	mv	a0,s2
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	2e2080e7          	jalr	738(ra) # 8000401a <iunlockput>
  iunlockput(dp);
    80005d40:	8526                	mv	a0,s1
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	2d8080e7          	jalr	728(ra) # 8000401a <iunlockput>
  end_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	ab8080e7          	jalr	-1352(ra) # 80004802 <end_op>
  return -1;
    80005d52:	557d                	li	a0,-1
}
    80005d54:	70ae                	ld	ra,232(sp)
    80005d56:	740e                	ld	s0,224(sp)
    80005d58:	64ee                	ld	s1,216(sp)
    80005d5a:	694e                	ld	s2,208(sp)
    80005d5c:	69ae                	ld	s3,200(sp)
    80005d5e:	616d                	addi	sp,sp,240
    80005d60:	8082                	ret

0000000080005d62 <sys_open>:

uint64
sys_open(void)
{
    80005d62:	7131                	addi	sp,sp,-192
    80005d64:	fd06                	sd	ra,184(sp)
    80005d66:	f922                	sd	s0,176(sp)
    80005d68:	f526                	sd	s1,168(sp)
    80005d6a:	f14a                	sd	s2,160(sp)
    80005d6c:	ed4e                	sd	s3,152(sp)
    80005d6e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d70:	f4c40593          	addi	a1,s0,-180
    80005d74:	4505                	li	a0,1
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	25c080e7          	jalr	604(ra) # 80002fd2 <argint>
  if ((n = argstr(0, path, MAXPATH)) < 0)
    80005d7e:	08000613          	li	a2,128
    80005d82:	f5040593          	addi	a1,s0,-176
    80005d86:	4501                	li	a0,0
    80005d88:	ffffd097          	auipc	ra,0xffffd
    80005d8c:	28a080e7          	jalr	650(ra) # 80003012 <argstr>
    80005d90:	87aa                	mv	a5,a0
    return -1;
    80005d92:	557d                	li	a0,-1
  if ((n = argstr(0, path, MAXPATH)) < 0)
    80005d94:	0a07c963          	bltz	a5,80005e46 <sys_open+0xe4>

  begin_op();
    80005d98:	fffff097          	auipc	ra,0xfffff
    80005d9c:	9ec080e7          	jalr	-1556(ra) # 80004784 <begin_op>

  if (omode & O_CREATE)
    80005da0:	f4c42783          	lw	a5,-180(s0)
    80005da4:	2007f793          	andi	a5,a5,512
    80005da8:	cfc5                	beqz	a5,80005e60 <sys_open+0xfe>
  {
    ip = create(path, T_FILE, 0, 0);
    80005daa:	4681                	li	a3,0
    80005dac:	4601                	li	a2,0
    80005dae:	4589                	li	a1,2
    80005db0:	f5040513          	addi	a0,s0,-176
    80005db4:	00000097          	auipc	ra,0x0
    80005db8:	972080e7          	jalr	-1678(ra) # 80005726 <create>
    80005dbc:	84aa                	mv	s1,a0
    if (ip == 0)
    80005dbe:	c959                	beqz	a0,80005e54 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if (ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV))
    80005dc0:	04449703          	lh	a4,68(s1)
    80005dc4:	478d                	li	a5,3
    80005dc6:	00f71763          	bne	a4,a5,80005dd4 <sys_open+0x72>
    80005dca:	0464d703          	lhu	a4,70(s1)
    80005dce:	47a5                	li	a5,9
    80005dd0:	0ce7ed63          	bltu	a5,a4,80005eaa <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if ((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	dbc080e7          	jalr	-580(ra) # 80004b90 <filealloc>
    80005ddc:	89aa                	mv	s3,a0
    80005dde:	10050363          	beqz	a0,80005ee4 <sys_open+0x182>
    80005de2:	00000097          	auipc	ra,0x0
    80005de6:	902080e7          	jalr	-1790(ra) # 800056e4 <fdalloc>
    80005dea:	892a                	mv	s2,a0
    80005dec:	0e054763          	bltz	a0,80005eda <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if (ip->type == T_DEVICE)
    80005df0:	04449703          	lh	a4,68(s1)
    80005df4:	478d                	li	a5,3
    80005df6:	0cf70563          	beq	a4,a5,80005ec0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  }
  else
  {
    f->type = FD_INODE;
    80005dfa:	4789                	li	a5,2
    80005dfc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e00:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e04:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e08:	f4c42783          	lw	a5,-180(s0)
    80005e0c:	0017c713          	xori	a4,a5,1
    80005e10:	8b05                	andi	a4,a4,1
    80005e12:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e16:	0037f713          	andi	a4,a5,3
    80005e1a:	00e03733          	snez	a4,a4
    80005e1e:	00e984a3          	sb	a4,9(s3)

  if ((omode & O_TRUNC) && ip->type == T_FILE)
    80005e22:	4007f793          	andi	a5,a5,1024
    80005e26:	c791                	beqz	a5,80005e32 <sys_open+0xd0>
    80005e28:	04449703          	lh	a4,68(s1)
    80005e2c:	4789                	li	a5,2
    80005e2e:	0af70063          	beq	a4,a5,80005ece <sys_open+0x16c>
  {
    itrunc(ip);
  }

  iunlock(ip);
    80005e32:	8526                	mv	a0,s1
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	046080e7          	jalr	70(ra) # 80003e7a <iunlock>
  end_op();
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	9c6080e7          	jalr	-1594(ra) # 80004802 <end_op>

  return fd;
    80005e44:	854a                	mv	a0,s2
}
    80005e46:	70ea                	ld	ra,184(sp)
    80005e48:	744a                	ld	s0,176(sp)
    80005e4a:	74aa                	ld	s1,168(sp)
    80005e4c:	790a                	ld	s2,160(sp)
    80005e4e:	69ea                	ld	s3,152(sp)
    80005e50:	6129                	addi	sp,sp,192
    80005e52:	8082                	ret
      end_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	9ae080e7          	jalr	-1618(ra) # 80004802 <end_op>
      return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	b7e5                	j	80005e46 <sys_open+0xe4>
    if ((ip = namei(path)) == 0)
    80005e60:	f5040513          	addi	a0,s0,-176
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	700080e7          	jalr	1792(ra) # 80004564 <namei>
    80005e6c:	84aa                	mv	s1,a0
    80005e6e:	c905                	beqz	a0,80005e9e <sys_open+0x13c>
    ilock(ip);
    80005e70:	ffffe097          	auipc	ra,0xffffe
    80005e74:	f48080e7          	jalr	-184(ra) # 80003db8 <ilock>
    if (ip->type == T_DIR && omode != O_RDONLY)
    80005e78:	04449703          	lh	a4,68(s1)
    80005e7c:	4785                	li	a5,1
    80005e7e:	f4f711e3          	bne	a4,a5,80005dc0 <sys_open+0x5e>
    80005e82:	f4c42783          	lw	a5,-180(s0)
    80005e86:	d7b9                	beqz	a5,80005dd4 <sys_open+0x72>
      iunlockput(ip);
    80005e88:	8526                	mv	a0,s1
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	190080e7          	jalr	400(ra) # 8000401a <iunlockput>
      end_op();
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	970080e7          	jalr	-1680(ra) # 80004802 <end_op>
      return -1;
    80005e9a:	557d                	li	a0,-1
    80005e9c:	b76d                	j	80005e46 <sys_open+0xe4>
      end_op();
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	964080e7          	jalr	-1692(ra) # 80004802 <end_op>
      return -1;
    80005ea6:	557d                	li	a0,-1
    80005ea8:	bf79                	j	80005e46 <sys_open+0xe4>
    iunlockput(ip);
    80005eaa:	8526                	mv	a0,s1
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	16e080e7          	jalr	366(ra) # 8000401a <iunlockput>
    end_op();
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	94e080e7          	jalr	-1714(ra) # 80004802 <end_op>
    return -1;
    80005ebc:	557d                	li	a0,-1
    80005ebe:	b761                	j	80005e46 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ec0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ec4:	04649783          	lh	a5,70(s1)
    80005ec8:	02f99223          	sh	a5,36(s3)
    80005ecc:	bf25                	j	80005e04 <sys_open+0xa2>
    itrunc(ip);
    80005ece:	8526                	mv	a0,s1
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	ff6080e7          	jalr	-10(ra) # 80003ec6 <itrunc>
    80005ed8:	bfa9                	j	80005e32 <sys_open+0xd0>
      fileclose(f);
    80005eda:	854e                	mv	a0,s3
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	d70080e7          	jalr	-656(ra) # 80004c4c <fileclose>
    iunlockput(ip);
    80005ee4:	8526                	mv	a0,s1
    80005ee6:	ffffe097          	auipc	ra,0xffffe
    80005eea:	134080e7          	jalr	308(ra) # 8000401a <iunlockput>
    end_op();
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	914080e7          	jalr	-1772(ra) # 80004802 <end_op>
    return -1;
    80005ef6:	557d                	li	a0,-1
    80005ef8:	b7b9                	j	80005e46 <sys_open+0xe4>

0000000080005efa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005efa:	7175                	addi	sp,sp,-144
    80005efc:	e506                	sd	ra,136(sp)
    80005efe:	e122                	sd	s0,128(sp)
    80005f00:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	882080e7          	jalr	-1918(ra) # 80004784 <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0)
    80005f0a:	08000613          	li	a2,128
    80005f0e:	f7040593          	addi	a1,s0,-144
    80005f12:	4501                	li	a0,0
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	0fe080e7          	jalr	254(ra) # 80003012 <argstr>
    80005f1c:	02054963          	bltz	a0,80005f4e <sys_mkdir+0x54>
    80005f20:	4681                	li	a3,0
    80005f22:	4601                	li	a2,0
    80005f24:	4585                	li	a1,1
    80005f26:	f7040513          	addi	a0,s0,-144
    80005f2a:	fffff097          	auipc	ra,0xfffff
    80005f2e:	7fc080e7          	jalr	2044(ra) # 80005726 <create>
    80005f32:	cd11                	beqz	a0,80005f4e <sys_mkdir+0x54>
  {
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	0e6080e7          	jalr	230(ra) # 8000401a <iunlockput>
  end_op();
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	8c6080e7          	jalr	-1850(ra) # 80004802 <end_op>
  return 0;
    80005f44:	4501                	li	a0,0
}
    80005f46:	60aa                	ld	ra,136(sp)
    80005f48:	640a                	ld	s0,128(sp)
    80005f4a:	6149                	addi	sp,sp,144
    80005f4c:	8082                	ret
    end_op();
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	8b4080e7          	jalr	-1868(ra) # 80004802 <end_op>
    return -1;
    80005f56:	557d                	li	a0,-1
    80005f58:	b7fd                	j	80005f46 <sys_mkdir+0x4c>

0000000080005f5a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f5a:	7135                	addi	sp,sp,-160
    80005f5c:	ed06                	sd	ra,152(sp)
    80005f5e:	e922                	sd	s0,144(sp)
    80005f60:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	822080e7          	jalr	-2014(ra) # 80004784 <begin_op>
  argint(1, &major);
    80005f6a:	f6c40593          	addi	a1,s0,-148
    80005f6e:	4505                	li	a0,1
    80005f70:	ffffd097          	auipc	ra,0xffffd
    80005f74:	062080e7          	jalr	98(ra) # 80002fd2 <argint>
  argint(2, &minor);
    80005f78:	f6840593          	addi	a1,s0,-152
    80005f7c:	4509                	li	a0,2
    80005f7e:	ffffd097          	auipc	ra,0xffffd
    80005f82:	054080e7          	jalr	84(ra) # 80002fd2 <argint>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    80005f86:	08000613          	li	a2,128
    80005f8a:	f7040593          	addi	a1,s0,-144
    80005f8e:	4501                	li	a0,0
    80005f90:	ffffd097          	auipc	ra,0xffffd
    80005f94:	082080e7          	jalr	130(ra) # 80003012 <argstr>
    80005f98:	02054b63          	bltz	a0,80005fce <sys_mknod+0x74>
      (ip = create(path, T_DEVICE, major, minor)) == 0)
    80005f9c:	f6841683          	lh	a3,-152(s0)
    80005fa0:	f6c41603          	lh	a2,-148(s0)
    80005fa4:	458d                	li	a1,3
    80005fa6:	f7040513          	addi	a0,s0,-144
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	77c080e7          	jalr	1916(ra) # 80005726 <create>
  if ((argstr(0, path, MAXPATH)) < 0 ||
    80005fb2:	cd11                	beqz	a0,80005fce <sys_mknod+0x74>
  {
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	066080e7          	jalr	102(ra) # 8000401a <iunlockput>
  end_op();
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	846080e7          	jalr	-1978(ra) # 80004802 <end_op>
  return 0;
    80005fc4:	4501                	li	a0,0
}
    80005fc6:	60ea                	ld	ra,152(sp)
    80005fc8:	644a                	ld	s0,144(sp)
    80005fca:	610d                	addi	sp,sp,160
    80005fcc:	8082                	ret
    end_op();
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	834080e7          	jalr	-1996(ra) # 80004802 <end_op>
    return -1;
    80005fd6:	557d                	li	a0,-1
    80005fd8:	b7fd                	j	80005fc6 <sys_mknod+0x6c>

0000000080005fda <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fda:	7135                	addi	sp,sp,-160
    80005fdc:	ed06                	sd	ra,152(sp)
    80005fde:	e922                	sd	s0,144(sp)
    80005fe0:	e526                	sd	s1,136(sp)
    80005fe2:	e14a                	sd	s2,128(sp)
    80005fe4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fe6:	ffffc097          	auipc	ra,0xffffc
    80005fea:	b9c080e7          	jalr	-1124(ra) # 80001b82 <myproc>
    80005fee:	892a                	mv	s2,a0

  begin_op();
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	794080e7          	jalr	1940(ra) # 80004784 <begin_op>
  if (argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0)
    80005ff8:	08000613          	li	a2,128
    80005ffc:	f6040593          	addi	a1,s0,-160
    80006000:	4501                	li	a0,0
    80006002:	ffffd097          	auipc	ra,0xffffd
    80006006:	010080e7          	jalr	16(ra) # 80003012 <argstr>
    8000600a:	04054b63          	bltz	a0,80006060 <sys_chdir+0x86>
    8000600e:	f6040513          	addi	a0,s0,-160
    80006012:	ffffe097          	auipc	ra,0xffffe
    80006016:	552080e7          	jalr	1362(ra) # 80004564 <namei>
    8000601a:	84aa                	mv	s1,a0
    8000601c:	c131                	beqz	a0,80006060 <sys_chdir+0x86>
  {
    end_op();
    return -1;
  }
  ilock(ip);
    8000601e:	ffffe097          	auipc	ra,0xffffe
    80006022:	d9a080e7          	jalr	-614(ra) # 80003db8 <ilock>
  if (ip->type != T_DIR)
    80006026:	04449703          	lh	a4,68(s1)
    8000602a:	4785                	li	a5,1
    8000602c:	04f71063          	bne	a4,a5,8000606c <sys_chdir+0x92>
  {
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006030:	8526                	mv	a0,s1
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	e48080e7          	jalr	-440(ra) # 80003e7a <iunlock>
  iput(p->cwd);
    8000603a:	15093503          	ld	a0,336(s2)
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	f34080e7          	jalr	-204(ra) # 80003f72 <iput>
  end_op();
    80006046:	ffffe097          	auipc	ra,0xffffe
    8000604a:	7bc080e7          	jalr	1980(ra) # 80004802 <end_op>
  p->cwd = ip;
    8000604e:	14993823          	sd	s1,336(s2)
  return 0;
    80006052:	4501                	li	a0,0
}
    80006054:	60ea                	ld	ra,152(sp)
    80006056:	644a                	ld	s0,144(sp)
    80006058:	64aa                	ld	s1,136(sp)
    8000605a:	690a                	ld	s2,128(sp)
    8000605c:	610d                	addi	sp,sp,160
    8000605e:	8082                	ret
    end_op();
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	7a2080e7          	jalr	1954(ra) # 80004802 <end_op>
    return -1;
    80006068:	557d                	li	a0,-1
    8000606a:	b7ed                	j	80006054 <sys_chdir+0x7a>
    iunlockput(ip);
    8000606c:	8526                	mv	a0,s1
    8000606e:	ffffe097          	auipc	ra,0xffffe
    80006072:	fac080e7          	jalr	-84(ra) # 8000401a <iunlockput>
    end_op();
    80006076:	ffffe097          	auipc	ra,0xffffe
    8000607a:	78c080e7          	jalr	1932(ra) # 80004802 <end_op>
    return -1;
    8000607e:	557d                	li	a0,-1
    80006080:	bfd1                	j	80006054 <sys_chdir+0x7a>

0000000080006082 <sys_exec>:

uint64
sys_exec(void)
{
    80006082:	7145                	addi	sp,sp,-464
    80006084:	e786                	sd	ra,456(sp)
    80006086:	e3a2                	sd	s0,448(sp)
    80006088:	ff26                	sd	s1,440(sp)
    8000608a:	fb4a                	sd	s2,432(sp)
    8000608c:	f74e                	sd	s3,424(sp)
    8000608e:	f352                	sd	s4,416(sp)
    80006090:	ef56                	sd	s5,408(sp)
    80006092:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006094:	e3840593          	addi	a1,s0,-456
    80006098:	4505                	li	a0,1
    8000609a:	ffffd097          	auipc	ra,0xffffd
    8000609e:	f58080e7          	jalr	-168(ra) # 80002ff2 <argaddr>
  if (argstr(0, path, MAXPATH) < 0)
    800060a2:	08000613          	li	a2,128
    800060a6:	f4040593          	addi	a1,s0,-192
    800060aa:	4501                	li	a0,0
    800060ac:	ffffd097          	auipc	ra,0xffffd
    800060b0:	f66080e7          	jalr	-154(ra) # 80003012 <argstr>
    800060b4:	87aa                	mv	a5,a0
  {
    return -1;
    800060b6:	557d                	li	a0,-1
  if (argstr(0, path, MAXPATH) < 0)
    800060b8:	0c07c363          	bltz	a5,8000617e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800060bc:	10000613          	li	a2,256
    800060c0:	4581                	li	a1,0
    800060c2:	e4040513          	addi	a0,s0,-448
    800060c6:	ffffb097          	auipc	ra,0xffffb
    800060ca:	db8080e7          	jalr	-584(ra) # 80000e7e <memset>
  for (i = 0;; i++)
  {
    if (i >= NELEM(argv))
    800060ce:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060d2:	89a6                	mv	s3,s1
    800060d4:	4901                	li	s2,0
    if (i >= NELEM(argv))
    800060d6:	02000a13          	li	s4,32
    800060da:	00090a9b          	sext.w	s5,s2
    {
      goto bad;
    }
    if (fetchaddr(uargv + sizeof(uint64) * i, (uint64 *)&uarg) < 0)
    800060de:	00391513          	slli	a0,s2,0x3
    800060e2:	e3040593          	addi	a1,s0,-464
    800060e6:	e3843783          	ld	a5,-456(s0)
    800060ea:	953e                	add	a0,a0,a5
    800060ec:	ffffd097          	auipc	ra,0xffffd
    800060f0:	e48080e7          	jalr	-440(ra) # 80002f34 <fetchaddr>
    800060f4:	02054a63          	bltz	a0,80006128 <sys_exec+0xa6>
    {
      goto bad;
    }
    if (uarg == 0)
    800060f8:	e3043783          	ld	a5,-464(s0)
    800060fc:	c3b9                	beqz	a5,80006142 <sys_exec+0xc0>
    {
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	b56080e7          	jalr	-1194(ra) # 80000c54 <kalloc>
    80006106:	85aa                	mv	a1,a0
    80006108:	00a9b023          	sd	a0,0(s3)
    if (argv[i] == 0)
    8000610c:	cd11                	beqz	a0,80006128 <sys_exec+0xa6>
      goto bad;
    if (fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000610e:	6605                	lui	a2,0x1
    80006110:	e3043503          	ld	a0,-464(s0)
    80006114:	ffffd097          	auipc	ra,0xffffd
    80006118:	e72080e7          	jalr	-398(ra) # 80002f86 <fetchstr>
    8000611c:	00054663          	bltz	a0,80006128 <sys_exec+0xa6>
    if (i >= NELEM(argv))
    80006120:	0905                	addi	s2,s2,1
    80006122:	09a1                	addi	s3,s3,8
    80006124:	fb491be3          	bne	s2,s4,800060da <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

bad:
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006128:	f4040913          	addi	s2,s0,-192
    8000612c:	6088                	ld	a0,0(s1)
    8000612e:	c539                	beqz	a0,8000617c <sys_exec+0xfa>
    kfree(argv[i]);
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	984080e7          	jalr	-1660(ra) # 80000ab4 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006138:	04a1                	addi	s1,s1,8
    8000613a:	ff2499e3          	bne	s1,s2,8000612c <sys_exec+0xaa>
  return -1;
    8000613e:	557d                	li	a0,-1
    80006140:	a83d                	j	8000617e <sys_exec+0xfc>
      argv[i] = 0;
    80006142:	0a8e                	slli	s5,s5,0x3
    80006144:	fc0a8793          	addi	a5,s5,-64
    80006148:	00878ab3          	add	s5,a5,s0
    8000614c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006150:	e4040593          	addi	a1,s0,-448
    80006154:	f4040513          	addi	a0,s0,-192
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	16e080e7          	jalr	366(ra) # 800052c6 <exec>
    80006160:	892a                	mv	s2,a0
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006162:	f4040993          	addi	s3,s0,-192
    80006166:	6088                	ld	a0,0(s1)
    80006168:	c901                	beqz	a0,80006178 <sys_exec+0xf6>
    kfree(argv[i]);
    8000616a:	ffffb097          	auipc	ra,0xffffb
    8000616e:	94a080e7          	jalr	-1718(ra) # 80000ab4 <kfree>
  for (i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006172:	04a1                	addi	s1,s1,8
    80006174:	ff3499e3          	bne	s1,s3,80006166 <sys_exec+0xe4>
  return ret;
    80006178:	854a                	mv	a0,s2
    8000617a:	a011                	j	8000617e <sys_exec+0xfc>
  return -1;
    8000617c:	557d                	li	a0,-1
}
    8000617e:	60be                	ld	ra,456(sp)
    80006180:	641e                	ld	s0,448(sp)
    80006182:	74fa                	ld	s1,440(sp)
    80006184:	795a                	ld	s2,432(sp)
    80006186:	79ba                	ld	s3,424(sp)
    80006188:	7a1a                	ld	s4,416(sp)
    8000618a:	6afa                	ld	s5,408(sp)
    8000618c:	6179                	addi	sp,sp,464
    8000618e:	8082                	ret

0000000080006190 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006190:	7139                	addi	sp,sp,-64
    80006192:	fc06                	sd	ra,56(sp)
    80006194:	f822                	sd	s0,48(sp)
    80006196:	f426                	sd	s1,40(sp)
    80006198:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000619a:	ffffc097          	auipc	ra,0xffffc
    8000619e:	9e8080e7          	jalr	-1560(ra) # 80001b82 <myproc>
    800061a2:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800061a4:	fd840593          	addi	a1,s0,-40
    800061a8:	4501                	li	a0,0
    800061aa:	ffffd097          	auipc	ra,0xffffd
    800061ae:	e48080e7          	jalr	-440(ra) # 80002ff2 <argaddr>
  if (pipealloc(&rf, &wf) < 0)
    800061b2:	fc840593          	addi	a1,s0,-56
    800061b6:	fd040513          	addi	a0,s0,-48
    800061ba:	fffff097          	auipc	ra,0xfffff
    800061be:	dc2080e7          	jalr	-574(ra) # 80004f7c <pipealloc>
    return -1;
    800061c2:	57fd                	li	a5,-1
  if (pipealloc(&rf, &wf) < 0)
    800061c4:	0c054463          	bltz	a0,8000628c <sys_pipe+0xfc>
  fd0 = -1;
    800061c8:	fcf42223          	sw	a5,-60(s0)
  if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0)
    800061cc:	fd043503          	ld	a0,-48(s0)
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	514080e7          	jalr	1300(ra) # 800056e4 <fdalloc>
    800061d8:	fca42223          	sw	a0,-60(s0)
    800061dc:	08054b63          	bltz	a0,80006272 <sys_pipe+0xe2>
    800061e0:	fc843503          	ld	a0,-56(s0)
    800061e4:	fffff097          	auipc	ra,0xfffff
    800061e8:	500080e7          	jalr	1280(ra) # 800056e4 <fdalloc>
    800061ec:	fca42023          	sw	a0,-64(s0)
    800061f0:	06054863          	bltz	a0,80006260 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    800061f4:	4691                	li	a3,4
    800061f6:	fc440613          	addi	a2,s0,-60
    800061fa:	fd843583          	ld	a1,-40(s0)
    800061fe:	68a8                	ld	a0,80(s1)
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	60e080e7          	jalr	1550(ra) # 8000180e <copyout>
    80006208:	02054063          	bltz	a0,80006228 <sys_pipe+0x98>
      copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0)
    8000620c:	4691                	li	a3,4
    8000620e:	fc040613          	addi	a2,s0,-64
    80006212:	fd843583          	ld	a1,-40(s0)
    80006216:	0591                	addi	a1,a1,4
    80006218:	68a8                	ld	a0,80(s1)
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	5f4080e7          	jalr	1524(ra) # 8000180e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006222:	4781                	li	a5,0
  if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
    80006224:	06055463          	bgez	a0,8000628c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006228:	fc442783          	lw	a5,-60(s0)
    8000622c:	07e9                	addi	a5,a5,26
    8000622e:	078e                	slli	a5,a5,0x3
    80006230:	97a6                	add	a5,a5,s1
    80006232:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006236:	fc042783          	lw	a5,-64(s0)
    8000623a:	07e9                	addi	a5,a5,26
    8000623c:	078e                	slli	a5,a5,0x3
    8000623e:	94be                	add	s1,s1,a5
    80006240:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006244:	fd043503          	ld	a0,-48(s0)
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	a04080e7          	jalr	-1532(ra) # 80004c4c <fileclose>
    fileclose(wf);
    80006250:	fc843503          	ld	a0,-56(s0)
    80006254:	fffff097          	auipc	ra,0xfffff
    80006258:	9f8080e7          	jalr	-1544(ra) # 80004c4c <fileclose>
    return -1;
    8000625c:	57fd                	li	a5,-1
    8000625e:	a03d                	j	8000628c <sys_pipe+0xfc>
    if (fd0 >= 0)
    80006260:	fc442783          	lw	a5,-60(s0)
    80006264:	0007c763          	bltz	a5,80006272 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006268:	07e9                	addi	a5,a5,26
    8000626a:	078e                	slli	a5,a5,0x3
    8000626c:	97a6                	add	a5,a5,s1
    8000626e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006272:	fd043503          	ld	a0,-48(s0)
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	9d6080e7          	jalr	-1578(ra) # 80004c4c <fileclose>
    fileclose(wf);
    8000627e:	fc843503          	ld	a0,-56(s0)
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	9ca080e7          	jalr	-1590(ra) # 80004c4c <fileclose>
    return -1;
    8000628a:	57fd                	li	a5,-1
}
    8000628c:	853e                	mv	a0,a5
    8000628e:	70e2                	ld	ra,56(sp)
    80006290:	7442                	ld	s0,48(sp)
    80006292:	74a2                	ld	s1,40(sp)
    80006294:	6121                	addi	sp,sp,64
    80006296:	8082                	ret
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	8ebfc0ef          	jal	ra,80002bca <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffb097          	auipc	ra,0xffffb
    8000637c:	7de080e7          	jalr	2014(ra) # 80001b56 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	97aa                	add	a5,a5,a0
    8000639c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	7a6080e7          	jalr	1958(ra) # 80001b56 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5151b          	slliw	a0,a0,0xd
    800063bc:	0c2017b7          	lui	a5,0xc201
    800063c0:	97aa                	add	a5,a5,a0
  return irq;
}
    800063c2:	43c8                	lw	a0,4(a5)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffb097          	auipc	ra,0xffffb
    800063dc:	77e080e7          	jalr	1918(ra) # 80001b56 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	04a7cc63          	blt	a5,a0,80006458 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0023d797          	auipc	a5,0x23d
    80006408:	94c78793          	addi	a5,a5,-1716 # 80242d50 <disk>
    8000640c:	97aa                	add	a5,a5,a0
    8000640e:	0187c783          	lbu	a5,24(a5)
    80006412:	ebb9                	bnez	a5,80006468 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006414:	00451693          	slli	a3,a0,0x4
    80006418:	0023d797          	auipc	a5,0x23d
    8000641c:	93878793          	addi	a5,a5,-1736 # 80242d50 <disk>
    80006420:	6398                	ld	a4,0(a5)
    80006422:	9736                	add	a4,a4,a3
    80006424:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006428:	6398                	ld	a4,0(a5)
    8000642a:	9736                	add	a4,a4,a3
    8000642c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006430:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006434:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006438:	97aa                	add	a5,a5,a0
    8000643a:	4705                	li	a4,1
    8000643c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006440:	0023d517          	auipc	a0,0x23d
    80006444:	92850513          	addi	a0,a0,-1752 # 80242d68 <disk+0x18>
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	024080e7          	jalr	36(ra) # 8000246c <wakeup>
}
    80006450:	60a2                	ld	ra,8(sp)
    80006452:	6402                	ld	s0,0(sp)
    80006454:	0141                	addi	sp,sp,16
    80006456:	8082                	ret
    panic("free_desc 1");
    80006458:	00002517          	auipc	a0,0x2
    8000645c:	61050513          	addi	a0,a0,1552 # 80008a68 <syscallnames+0x3f8>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	0e0080e7          	jalr	224(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006468:	00002517          	auipc	a0,0x2
    8000646c:	61050513          	addi	a0,a0,1552 # 80008a78 <syscallnames+0x408>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	0d0080e7          	jalr	208(ra) # 80000540 <panic>

0000000080006478 <virtio_disk_init>:
{
    80006478:	1101                	addi	sp,sp,-32
    8000647a:	ec06                	sd	ra,24(sp)
    8000647c:	e822                	sd	s0,16(sp)
    8000647e:	e426                	sd	s1,8(sp)
    80006480:	e04a                	sd	s2,0(sp)
    80006482:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006484:	00002597          	auipc	a1,0x2
    80006488:	60458593          	addi	a1,a1,1540 # 80008a88 <syscallnames+0x418>
    8000648c:	0023d517          	auipc	a0,0x23d
    80006490:	9ec50513          	addi	a0,a0,-1556 # 80242e78 <disk+0x128>
    80006494:	ffffb097          	auipc	ra,0xffffb
    80006498:	85e080e7          	jalr	-1954(ra) # 80000cf2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000649c:	100017b7          	lui	a5,0x10001
    800064a0:	4398                	lw	a4,0(a5)
    800064a2:	2701                	sext.w	a4,a4
    800064a4:	747277b7          	lui	a5,0x74727
    800064a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064ac:	14f71b63          	bne	a4,a5,80006602 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064b0:	100017b7          	lui	a5,0x10001
    800064b4:	43dc                	lw	a5,4(a5)
    800064b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b8:	4709                	li	a4,2
    800064ba:	14e79463          	bne	a5,a4,80006602 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064be:	100017b7          	lui	a5,0x10001
    800064c2:	479c                	lw	a5,8(a5)
    800064c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064c6:	12e79e63          	bne	a5,a4,80006602 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064ca:	100017b7          	lui	a5,0x10001
    800064ce:	47d8                	lw	a4,12(a5)
    800064d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d2:	554d47b7          	lui	a5,0x554d4
    800064d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064da:	12f71463          	bne	a4,a5,80006602 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064de:	100017b7          	lui	a5,0x10001
    800064e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e6:	4705                	li	a4,1
    800064e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ea:	470d                	li	a4,3
    800064ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064ee:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064f0:	c7ffe6b7          	lui	a3,0xc7ffe
    800064f4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb8cf>
    800064f8:	8f75                	and	a4,a4,a3
    800064fa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064fc:	472d                	li	a4,11
    800064fe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006500:	5bbc                	lw	a5,112(a5)
    80006502:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006506:	8ba1                	andi	a5,a5,8
    80006508:	10078563          	beqz	a5,80006612 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000650c:	100017b7          	lui	a5,0x10001
    80006510:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006514:	43fc                	lw	a5,68(a5)
    80006516:	2781                	sext.w	a5,a5
    80006518:	10079563          	bnez	a5,80006622 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000651c:	100017b7          	lui	a5,0x10001
    80006520:	5bdc                	lw	a5,52(a5)
    80006522:	2781                	sext.w	a5,a5
  if(max == 0)
    80006524:	10078763          	beqz	a5,80006632 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006528:	471d                	li	a4,7
    8000652a:	10f77c63          	bgeu	a4,a5,80006642 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000652e:	ffffa097          	auipc	ra,0xffffa
    80006532:	726080e7          	jalr	1830(ra) # 80000c54 <kalloc>
    80006536:	0023d497          	auipc	s1,0x23d
    8000653a:	81a48493          	addi	s1,s1,-2022 # 80242d50 <disk>
    8000653e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	714080e7          	jalr	1812(ra) # 80000c54 <kalloc>
    80006548:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	70a080e7          	jalr	1802(ra) # 80000c54 <kalloc>
    80006552:	87aa                	mv	a5,a0
    80006554:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006556:	6088                	ld	a0,0(s1)
    80006558:	cd6d                	beqz	a0,80006652 <virtio_disk_init+0x1da>
    8000655a:	0023c717          	auipc	a4,0x23c
    8000655e:	7fe73703          	ld	a4,2046(a4) # 80242d58 <disk+0x8>
    80006562:	cb65                	beqz	a4,80006652 <virtio_disk_init+0x1da>
    80006564:	c7fd                	beqz	a5,80006652 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006566:	6605                	lui	a2,0x1
    80006568:	4581                	li	a1,0
    8000656a:	ffffb097          	auipc	ra,0xffffb
    8000656e:	914080e7          	jalr	-1772(ra) # 80000e7e <memset>
  memset(disk.avail, 0, PGSIZE);
    80006572:	0023c497          	auipc	s1,0x23c
    80006576:	7de48493          	addi	s1,s1,2014 # 80242d50 <disk>
    8000657a:	6605                	lui	a2,0x1
    8000657c:	4581                	li	a1,0
    8000657e:	6488                	ld	a0,8(s1)
    80006580:	ffffb097          	auipc	ra,0xffffb
    80006584:	8fe080e7          	jalr	-1794(ra) # 80000e7e <memset>
  memset(disk.used, 0, PGSIZE);
    80006588:	6605                	lui	a2,0x1
    8000658a:	4581                	li	a1,0
    8000658c:	6888                	ld	a0,16(s1)
    8000658e:	ffffb097          	auipc	ra,0xffffb
    80006592:	8f0080e7          	jalr	-1808(ra) # 80000e7e <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006596:	100017b7          	lui	a5,0x10001
    8000659a:	4721                	li	a4,8
    8000659c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000659e:	4098                	lw	a4,0(s1)
    800065a0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800065a4:	40d8                	lw	a4,4(s1)
    800065a6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800065aa:	6498                	ld	a4,8(s1)
    800065ac:	0007069b          	sext.w	a3,a4
    800065b0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065b4:	9701                	srai	a4,a4,0x20
    800065b6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065ba:	6898                	ld	a4,16(s1)
    800065bc:	0007069b          	sext.w	a3,a4
    800065c0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065c4:	9701                	srai	a4,a4,0x20
    800065c6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800065ca:	4705                	li	a4,1
    800065cc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800065ce:	00e48c23          	sb	a4,24(s1)
    800065d2:	00e48ca3          	sb	a4,25(s1)
    800065d6:	00e48d23          	sb	a4,26(s1)
    800065da:	00e48da3          	sb	a4,27(s1)
    800065de:	00e48e23          	sb	a4,28(s1)
    800065e2:	00e48ea3          	sb	a4,29(s1)
    800065e6:	00e48f23          	sb	a4,30(s1)
    800065ea:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065ee:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f2:	0727a823          	sw	s2,112(a5)
}
    800065f6:	60e2                	ld	ra,24(sp)
    800065f8:	6442                	ld	s0,16(sp)
    800065fa:	64a2                	ld	s1,8(sp)
    800065fc:	6902                	ld	s2,0(sp)
    800065fe:	6105                	addi	sp,sp,32
    80006600:	8082                	ret
    panic("could not find virtio disk");
    80006602:	00002517          	auipc	a0,0x2
    80006606:	49650513          	addi	a0,a0,1174 # 80008a98 <syscallnames+0x428>
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	f36080e7          	jalr	-202(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006612:	00002517          	auipc	a0,0x2
    80006616:	4a650513          	addi	a0,a0,1190 # 80008ab8 <syscallnames+0x448>
    8000661a:	ffffa097          	auipc	ra,0xffffa
    8000661e:	f26080e7          	jalr	-218(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006622:	00002517          	auipc	a0,0x2
    80006626:	4b650513          	addi	a0,a0,1206 # 80008ad8 <syscallnames+0x468>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	f16080e7          	jalr	-234(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	4c650513          	addi	a0,a0,1222 # 80008af8 <syscallnames+0x488>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f06080e7          	jalr	-250(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006642:	00002517          	auipc	a0,0x2
    80006646:	4d650513          	addi	a0,a0,1238 # 80008b18 <syscallnames+0x4a8>
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	4e650513          	addi	a0,a0,1254 # 80008b38 <syscallnames+0x4c8>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ee6080e7          	jalr	-282(ra) # 80000540 <panic>

0000000080006662 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006662:	7119                	addi	sp,sp,-128
    80006664:	fc86                	sd	ra,120(sp)
    80006666:	f8a2                	sd	s0,112(sp)
    80006668:	f4a6                	sd	s1,104(sp)
    8000666a:	f0ca                	sd	s2,96(sp)
    8000666c:	ecce                	sd	s3,88(sp)
    8000666e:	e8d2                	sd	s4,80(sp)
    80006670:	e4d6                	sd	s5,72(sp)
    80006672:	e0da                	sd	s6,64(sp)
    80006674:	fc5e                	sd	s7,56(sp)
    80006676:	f862                	sd	s8,48(sp)
    80006678:	f466                	sd	s9,40(sp)
    8000667a:	f06a                	sd	s10,32(sp)
    8000667c:	ec6e                	sd	s11,24(sp)
    8000667e:	0100                	addi	s0,sp,128
    80006680:	8aaa                	mv	s5,a0
    80006682:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006684:	00c52d03          	lw	s10,12(a0)
    80006688:	001d1d1b          	slliw	s10,s10,0x1
    8000668c:	1d02                	slli	s10,s10,0x20
    8000668e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006692:	0023c517          	auipc	a0,0x23c
    80006696:	7e650513          	addi	a0,a0,2022 # 80242e78 <disk+0x128>
    8000669a:	ffffa097          	auipc	ra,0xffffa
    8000669e:	6e8080e7          	jalr	1768(ra) # 80000d82 <acquire>
  for(int i = 0; i < 3; i++){
    800066a2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066a4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800066a6:	0023cb97          	auipc	s7,0x23c
    800066aa:	6aab8b93          	addi	s7,s7,1706 # 80242d50 <disk>
  for(int i = 0; i < 3; i++){
    800066ae:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066b0:	0023cc97          	auipc	s9,0x23c
    800066b4:	7c8c8c93          	addi	s9,s9,1992 # 80242e78 <disk+0x128>
    800066b8:	a08d                	j	8000671a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800066ba:	00fb8733          	add	a4,s7,a5
    800066be:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800066c2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800066c4:	0207c563          	bltz	a5,800066ee <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800066c8:	2905                	addiw	s2,s2,1
    800066ca:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800066cc:	05690c63          	beq	s2,s6,80006724 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066d0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066d2:	0023c717          	auipc	a4,0x23c
    800066d6:	67e70713          	addi	a4,a4,1662 # 80242d50 <disk>
    800066da:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066dc:	01874683          	lbu	a3,24(a4)
    800066e0:	fee9                	bnez	a3,800066ba <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800066e2:	2785                	addiw	a5,a5,1
    800066e4:	0705                	addi	a4,a4,1
    800066e6:	fe979be3          	bne	a5,s1,800066dc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800066ea:	57fd                	li	a5,-1
    800066ec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800066ee:	01205d63          	blez	s2,80006708 <virtio_disk_rw+0xa6>
    800066f2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800066f4:	000a2503          	lw	a0,0(s4)
    800066f8:	00000097          	auipc	ra,0x0
    800066fc:	cfe080e7          	jalr	-770(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006700:	2d85                	addiw	s11,s11,1
    80006702:	0a11                	addi	s4,s4,4
    80006704:	ff2d98e3          	bne	s11,s2,800066f4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006708:	85e6                	mv	a1,s9
    8000670a:	0023c517          	auipc	a0,0x23c
    8000670e:	65e50513          	addi	a0,a0,1630 # 80242d68 <disk+0x18>
    80006712:	ffffc097          	auipc	ra,0xffffc
    80006716:	baa080e7          	jalr	-1110(ra) # 800022bc <sleep>
  for(int i = 0; i < 3; i++){
    8000671a:	f8040a13          	addi	s4,s0,-128
{
    8000671e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006720:	894e                	mv	s2,s3
    80006722:	b77d                	j	800066d0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006724:	f8042503          	lw	a0,-128(s0)
    80006728:	00a50713          	addi	a4,a0,10
    8000672c:	0712                	slli	a4,a4,0x4

  if(write)
    8000672e:	0023c797          	auipc	a5,0x23c
    80006732:	62278793          	addi	a5,a5,1570 # 80242d50 <disk>
    80006736:	00e786b3          	add	a3,a5,a4
    8000673a:	01803633          	snez	a2,s8
    8000673e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006740:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006744:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006748:	f6070613          	addi	a2,a4,-160
    8000674c:	6394                	ld	a3,0(a5)
    8000674e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006750:	00870593          	addi	a1,a4,8
    80006754:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006756:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006758:	0007b803          	ld	a6,0(a5)
    8000675c:	9642                	add	a2,a2,a6
    8000675e:	46c1                	li	a3,16
    80006760:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006762:	4585                	li	a1,1
    80006764:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006768:	f8442683          	lw	a3,-124(s0)
    8000676c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006770:	0692                	slli	a3,a3,0x4
    80006772:	9836                	add	a6,a6,a3
    80006774:	058a8613          	addi	a2,s5,88
    80006778:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000677c:	0007b803          	ld	a6,0(a5)
    80006780:	96c2                	add	a3,a3,a6
    80006782:	40000613          	li	a2,1024
    80006786:	c690                	sw	a2,8(a3)
  if(write)
    80006788:	001c3613          	seqz	a2,s8
    8000678c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006790:	00166613          	ori	a2,a2,1
    80006794:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006798:	f8842603          	lw	a2,-120(s0)
    8000679c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067a0:	00250693          	addi	a3,a0,2
    800067a4:	0692                	slli	a3,a3,0x4
    800067a6:	96be                	add	a3,a3,a5
    800067a8:	58fd                	li	a7,-1
    800067aa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067ae:	0612                	slli	a2,a2,0x4
    800067b0:	9832                	add	a6,a6,a2
    800067b2:	f9070713          	addi	a4,a4,-112
    800067b6:	973e                	add	a4,a4,a5
    800067b8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800067bc:	6398                	ld	a4,0(a5)
    800067be:	9732                	add	a4,a4,a2
    800067c0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067c2:	4609                	li	a2,2
    800067c4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800067c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067cc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800067d0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067d4:	6794                	ld	a3,8(a5)
    800067d6:	0026d703          	lhu	a4,2(a3)
    800067da:	8b1d                	andi	a4,a4,7
    800067dc:	0706                	slli	a4,a4,0x1
    800067de:	96ba                	add	a3,a3,a4
    800067e0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800067e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067e8:	6798                	ld	a4,8(a5)
    800067ea:	00275783          	lhu	a5,2(a4)
    800067ee:	2785                	addiw	a5,a5,1
    800067f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067f8:	100017b7          	lui	a5,0x10001
    800067fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006800:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006804:	0023c917          	auipc	s2,0x23c
    80006808:	67490913          	addi	s2,s2,1652 # 80242e78 <disk+0x128>
  while(b->disk == 1) {
    8000680c:	4485                	li	s1,1
    8000680e:	00b79c63          	bne	a5,a1,80006826 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006812:	85ca                	mv	a1,s2
    80006814:	8556                	mv	a0,s5
    80006816:	ffffc097          	auipc	ra,0xffffc
    8000681a:	aa6080e7          	jalr	-1370(ra) # 800022bc <sleep>
  while(b->disk == 1) {
    8000681e:	004aa783          	lw	a5,4(s5)
    80006822:	fe9788e3          	beq	a5,s1,80006812 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006826:	f8042903          	lw	s2,-128(s0)
    8000682a:	00290713          	addi	a4,s2,2
    8000682e:	0712                	slli	a4,a4,0x4
    80006830:	0023c797          	auipc	a5,0x23c
    80006834:	52078793          	addi	a5,a5,1312 # 80242d50 <disk>
    80006838:	97ba                	add	a5,a5,a4
    8000683a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000683e:	0023c997          	auipc	s3,0x23c
    80006842:	51298993          	addi	s3,s3,1298 # 80242d50 <disk>
    80006846:	00491713          	slli	a4,s2,0x4
    8000684a:	0009b783          	ld	a5,0(s3)
    8000684e:	97ba                	add	a5,a5,a4
    80006850:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006854:	854a                	mv	a0,s2
    80006856:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000685a:	00000097          	auipc	ra,0x0
    8000685e:	b9c080e7          	jalr	-1124(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006862:	8885                	andi	s1,s1,1
    80006864:	f0ed                	bnez	s1,80006846 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006866:	0023c517          	auipc	a0,0x23c
    8000686a:	61250513          	addi	a0,a0,1554 # 80242e78 <disk+0x128>
    8000686e:	ffffa097          	auipc	ra,0xffffa
    80006872:	5c8080e7          	jalr	1480(ra) # 80000e36 <release>
}
    80006876:	70e6                	ld	ra,120(sp)
    80006878:	7446                	ld	s0,112(sp)
    8000687a:	74a6                	ld	s1,104(sp)
    8000687c:	7906                	ld	s2,96(sp)
    8000687e:	69e6                	ld	s3,88(sp)
    80006880:	6a46                	ld	s4,80(sp)
    80006882:	6aa6                	ld	s5,72(sp)
    80006884:	6b06                	ld	s6,64(sp)
    80006886:	7be2                	ld	s7,56(sp)
    80006888:	7c42                	ld	s8,48(sp)
    8000688a:	7ca2                	ld	s9,40(sp)
    8000688c:	7d02                	ld	s10,32(sp)
    8000688e:	6de2                	ld	s11,24(sp)
    80006890:	6109                	addi	sp,sp,128
    80006892:	8082                	ret

0000000080006894 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006894:	1101                	addi	sp,sp,-32
    80006896:	ec06                	sd	ra,24(sp)
    80006898:	e822                	sd	s0,16(sp)
    8000689a:	e426                	sd	s1,8(sp)
    8000689c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000689e:	0023c497          	auipc	s1,0x23c
    800068a2:	4b248493          	addi	s1,s1,1202 # 80242d50 <disk>
    800068a6:	0023c517          	auipc	a0,0x23c
    800068aa:	5d250513          	addi	a0,a0,1490 # 80242e78 <disk+0x128>
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	4d4080e7          	jalr	1236(ra) # 80000d82 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068b6:	10001737          	lui	a4,0x10001
    800068ba:	533c                	lw	a5,96(a4)
    800068bc:	8b8d                	andi	a5,a5,3
    800068be:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068c0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068c4:	689c                	ld	a5,16(s1)
    800068c6:	0204d703          	lhu	a4,32(s1)
    800068ca:	0027d783          	lhu	a5,2(a5)
    800068ce:	04f70863          	beq	a4,a5,8000691e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068d2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068d6:	6898                	ld	a4,16(s1)
    800068d8:	0204d783          	lhu	a5,32(s1)
    800068dc:	8b9d                	andi	a5,a5,7
    800068de:	078e                	slli	a5,a5,0x3
    800068e0:	97ba                	add	a5,a5,a4
    800068e2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068e4:	00278713          	addi	a4,a5,2
    800068e8:	0712                	slli	a4,a4,0x4
    800068ea:	9726                	add	a4,a4,s1
    800068ec:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068f0:	e721                	bnez	a4,80006938 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068f2:	0789                	addi	a5,a5,2
    800068f4:	0792                	slli	a5,a5,0x4
    800068f6:	97a6                	add	a5,a5,s1
    800068f8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068fa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068fe:	ffffc097          	auipc	ra,0xffffc
    80006902:	b6e080e7          	jalr	-1170(ra) # 8000246c <wakeup>

    disk.used_idx += 1;
    80006906:	0204d783          	lhu	a5,32(s1)
    8000690a:	2785                	addiw	a5,a5,1
    8000690c:	17c2                	slli	a5,a5,0x30
    8000690e:	93c1                	srli	a5,a5,0x30
    80006910:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006914:	6898                	ld	a4,16(s1)
    80006916:	00275703          	lhu	a4,2(a4)
    8000691a:	faf71ce3          	bne	a4,a5,800068d2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000691e:	0023c517          	auipc	a0,0x23c
    80006922:	55a50513          	addi	a0,a0,1370 # 80242e78 <disk+0x128>
    80006926:	ffffa097          	auipc	ra,0xffffa
    8000692a:	510080e7          	jalr	1296(ra) # 80000e36 <release>
}
    8000692e:	60e2                	ld	ra,24(sp)
    80006930:	6442                	ld	s0,16(sp)
    80006932:	64a2                	ld	s1,8(sp)
    80006934:	6105                	addi	sp,sp,32
    80006936:	8082                	ret
      panic("virtio_disk_intr status");
    80006938:	00002517          	auipc	a0,0x2
    8000693c:	21850513          	addi	a0,a0,536 # 80008b50 <syscallnames+0x4e0>
    80006940:	ffffa097          	auipc	ra,0xffffa
    80006944:	c00080e7          	jalr	-1024(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
