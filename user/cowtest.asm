
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <simpletest>:
// allocate more than half of physical memory,
// then fork. this will fail in the default
// kernel, which does not support copy-on-write.
void
simpletest()
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = (phys_size / 3) * 2;

  printf("simple: ");
   e:	00001517          	auipc	a0,0x1
  12:	ca250513          	addi	a0,a0,-862 # cb0 <malloc+0xf4>
  16:	00001097          	auipc	ra,0x1
  1a:	aee080e7          	jalr	-1298(ra) # b04 <printf>
  
  char *p = sbrk(sz);
  1e:	05555537          	lui	a0,0x5555
  22:	55450513          	addi	a0,a0,1364 # 5555554 <base+0x5550544>
  26:	00000097          	auipc	ra,0x0
  2a:	7bc080e7          	jalr	1980(ra) # 7e2 <sbrk>
  if(p == (char*)0xffffffffffffffffL){
  2e:	57fd                	li	a5,-1
  30:	06f50563          	beq	a0,a5,9a <simpletest+0x9a>
  34:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  for(char *q = p; q < p + sz; q += 4096){
  36:	05556937          	lui	s2,0x5556
  3a:	992a                	add	s2,s2,a0
  3c:	6985                	lui	s3,0x1
    *(int*)q = getpid();
  3e:	00000097          	auipc	ra,0x0
  42:	79c080e7          	jalr	1948(ra) # 7da <getpid>
  46:	c088                	sw	a0,0(s1)
  for(char *q = p; q < p + sz; q += 4096){
  48:	94ce                	add	s1,s1,s3
  4a:	fe991ae3          	bne	s2,s1,3e <simpletest+0x3e>
  }

  int pid = fork();
  4e:	00000097          	auipc	ra,0x0
  52:	704080e7          	jalr	1796(ra) # 752 <fork>
  if(pid < 0){
  56:	06054363          	bltz	a0,bc <simpletest+0xbc>
    printf("fork() failed\n");
    exit(-1);
  }

  if(pid == 0)
  5a:	cd35                	beqz	a0,d6 <simpletest+0xd6>
    exit(0);

  wait(0);
  5c:	4501                	li	a0,0
  5e:	00000097          	auipc	ra,0x0
  62:	704080e7          	jalr	1796(ra) # 762 <wait>

  if(sbrk(-sz) == (char*)0xffffffffffffffffL){
  66:	faaab537          	lui	a0,0xfaaab
  6a:	aac50513          	addi	a0,a0,-1364 # fffffffffaaaaaac <base+0xfffffffffaaa5a9c>
  6e:	00000097          	auipc	ra,0x0
  72:	774080e7          	jalr	1908(ra) # 7e2 <sbrk>
  76:	57fd                	li	a5,-1
  78:	06f50363          	beq	a0,a5,de <simpletest+0xde>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
  7c:	00001517          	auipc	a0,0x1
  80:	c8450513          	addi	a0,a0,-892 # d00 <malloc+0x144>
  84:	00001097          	auipc	ra,0x1
  88:	a80080e7          	jalr	-1408(ra) # b04 <printf>
}
  8c:	70a2                	ld	ra,40(sp)
  8e:	7402                	ld	s0,32(sp)
  90:	64e2                	ld	s1,24(sp)
  92:	6942                	ld	s2,16(sp)
  94:	69a2                	ld	s3,8(sp)
  96:	6145                	addi	sp,sp,48
  98:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
  9a:	055555b7          	lui	a1,0x5555
  9e:	55458593          	addi	a1,a1,1364 # 5555554 <base+0x5550544>
  a2:	00001517          	auipc	a0,0x1
  a6:	c1e50513          	addi	a0,a0,-994 # cc0 <malloc+0x104>
  aa:	00001097          	auipc	ra,0x1
  ae:	a5a080e7          	jalr	-1446(ra) # b04 <printf>
    exit(-1);
  b2:	557d                	li	a0,-1
  b4:	00000097          	auipc	ra,0x0
  b8:	6a6080e7          	jalr	1702(ra) # 75a <exit>
    printf("fork() failed\n");
  bc:	00001517          	auipc	a0,0x1
  c0:	c1c50513          	addi	a0,a0,-996 # cd8 <malloc+0x11c>
  c4:	00001097          	auipc	ra,0x1
  c8:	a40080e7          	jalr	-1472(ra) # b04 <printf>
    exit(-1);
  cc:	557d                	li	a0,-1
  ce:	00000097          	auipc	ra,0x0
  d2:	68c080e7          	jalr	1676(ra) # 75a <exit>
    exit(0);
  d6:	00000097          	auipc	ra,0x0
  da:	684080e7          	jalr	1668(ra) # 75a <exit>
    printf("sbrk(-%d) failed\n", sz);
  de:	055555b7          	lui	a1,0x5555
  e2:	55458593          	addi	a1,a1,1364 # 5555554 <base+0x5550544>
  e6:	00001517          	auipc	a0,0x1
  ea:	c0250513          	addi	a0,a0,-1022 # ce8 <malloc+0x12c>
  ee:	00001097          	auipc	ra,0x1
  f2:	a16080e7          	jalr	-1514(ra) # b04 <printf>
    exit(-1);
  f6:	557d                	li	a0,-1
  f8:	00000097          	auipc	ra,0x0
  fc:	662080e7          	jalr	1634(ra) # 75a <exit>

0000000000000100 <threetest>:
// this causes more than half of physical memory
// to be allocated, so it also checks whether
// copied pages are freed.
void
threetest()
{
 100:	7179                	addi	sp,sp,-48
 102:	f406                	sd	ra,40(sp)
 104:	f022                	sd	s0,32(sp)
 106:	ec26                	sd	s1,24(sp)
 108:	e84a                	sd	s2,16(sp)
 10a:	e44e                	sd	s3,8(sp)
 10c:	e052                	sd	s4,0(sp)
 10e:	1800                	addi	s0,sp,48
  uint64 phys_size = PHYSTOP - KERNBASE;
  int sz = phys_size / 4;
  int pid1, pid2;

  printf("three: ");
 110:	00001517          	auipc	a0,0x1
 114:	bf850513          	addi	a0,a0,-1032 # d08 <malloc+0x14c>
 118:	00001097          	auipc	ra,0x1
 11c:	9ec080e7          	jalr	-1556(ra) # b04 <printf>
  
  char *p = sbrk(sz);
 120:	02000537          	lui	a0,0x2000
 124:	00000097          	auipc	ra,0x0
 128:	6be080e7          	jalr	1726(ra) # 7e2 <sbrk>
  if(p == (char*)0xffffffffffffffffL){
 12c:	57fd                	li	a5,-1
 12e:	08f50763          	beq	a0,a5,1bc <threetest+0xbc>
 132:	84aa                	mv	s1,a0
    printf("sbrk(%d) failed\n", sz);
    exit(-1);
  }

  pid1 = fork();
 134:	00000097          	auipc	ra,0x0
 138:	61e080e7          	jalr	1566(ra) # 752 <fork>
  if(pid1 < 0){
 13c:	08054f63          	bltz	a0,1da <threetest+0xda>
    printf("fork failed\n");
    exit(-1);
  }
  if(pid1 == 0){
 140:	c955                	beqz	a0,1f4 <threetest+0xf4>
      *(int*)q = 9999;
    }
    exit(0);
  }

  for(char *q = p; q < p + sz; q += 4096){
 142:	020009b7          	lui	s3,0x2000
 146:	99a6                	add	s3,s3,s1
 148:	8926                	mv	s2,s1
 14a:	6a05                	lui	s4,0x1
    *(int*)q = getpid();
 14c:	00000097          	auipc	ra,0x0
 150:	68e080e7          	jalr	1678(ra) # 7da <getpid>
 154:	00a92023          	sw	a0,0(s2) # 5556000 <base+0x5550ff0>
  for(char *q = p; q < p + sz; q += 4096){
 158:	9952                	add	s2,s2,s4
 15a:	ff3919e3          	bne	s2,s3,14c <threetest+0x4c>
  }

  wait(0);
 15e:	4501                	li	a0,0
 160:	00000097          	auipc	ra,0x0
 164:	602080e7          	jalr	1538(ra) # 762 <wait>

  sleep(1);
 168:	4505                	li	a0,1
 16a:	00000097          	auipc	ra,0x0
 16e:	680080e7          	jalr	1664(ra) # 7ea <sleep>

  for(char *q = p; q < p + sz; q += 4096){
 172:	6a05                	lui	s4,0x1
    if(*(int*)q != getpid()){
 174:	0004a903          	lw	s2,0(s1)
 178:	00000097          	auipc	ra,0x0
 17c:	662080e7          	jalr	1634(ra) # 7da <getpid>
 180:	10a91a63          	bne	s2,a0,294 <threetest+0x194>
  for(char *q = p; q < p + sz; q += 4096){
 184:	94d2                	add	s1,s1,s4
 186:	ff3497e3          	bne	s1,s3,174 <threetest+0x74>
      printf("wrong content\n");
      exit(-1);
    }
  }

  if(sbrk(-sz) == (char*)0xffffffffffffffffL){
 18a:	fe000537          	lui	a0,0xfe000
 18e:	00000097          	auipc	ra,0x0
 192:	654080e7          	jalr	1620(ra) # 7e2 <sbrk>
 196:	57fd                	li	a5,-1
 198:	10f50b63          	beq	a0,a5,2ae <threetest+0x1ae>
    printf("sbrk(-%d) failed\n", sz);
    exit(-1);
  }

  printf("ok\n");
 19c:	00001517          	auipc	a0,0x1
 1a0:	b6450513          	addi	a0,a0,-1180 # d00 <malloc+0x144>
 1a4:	00001097          	auipc	ra,0x1
 1a8:	960080e7          	jalr	-1696(ra) # b04 <printf>
}
 1ac:	70a2                	ld	ra,40(sp)
 1ae:	7402                	ld	s0,32(sp)
 1b0:	64e2                	ld	s1,24(sp)
 1b2:	6942                	ld	s2,16(sp)
 1b4:	69a2                	ld	s3,8(sp)
 1b6:	6a02                	ld	s4,0(sp)
 1b8:	6145                	addi	sp,sp,48
 1ba:	8082                	ret
    printf("sbrk(%d) failed\n", sz);
 1bc:	020005b7          	lui	a1,0x2000
 1c0:	00001517          	auipc	a0,0x1
 1c4:	b0050513          	addi	a0,a0,-1280 # cc0 <malloc+0x104>
 1c8:	00001097          	auipc	ra,0x1
 1cc:	93c080e7          	jalr	-1732(ra) # b04 <printf>
    exit(-1);
 1d0:	557d                	li	a0,-1
 1d2:	00000097          	auipc	ra,0x0
 1d6:	588080e7          	jalr	1416(ra) # 75a <exit>
    printf("fork failed\n");
 1da:	00001517          	auipc	a0,0x1
 1de:	b3650513          	addi	a0,a0,-1226 # d10 <malloc+0x154>
 1e2:	00001097          	auipc	ra,0x1
 1e6:	922080e7          	jalr	-1758(ra) # b04 <printf>
    exit(-1);
 1ea:	557d                	li	a0,-1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	56e080e7          	jalr	1390(ra) # 75a <exit>
    pid2 = fork();
 1f4:	00000097          	auipc	ra,0x0
 1f8:	55e080e7          	jalr	1374(ra) # 752 <fork>
    if(pid2 < 0){
 1fc:	04054263          	bltz	a0,240 <threetest+0x140>
    if(pid2 == 0){
 200:	ed29                	bnez	a0,25a <threetest+0x15a>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 202:	0199a9b7          	lui	s3,0x199a
 206:	99a6                	add	s3,s3,s1
 208:	8926                	mv	s2,s1
 20a:	6a05                	lui	s4,0x1
        *(int*)q = getpid();
 20c:	00000097          	auipc	ra,0x0
 210:	5ce080e7          	jalr	1486(ra) # 7da <getpid>
 214:	00a92023          	sw	a0,0(s2)
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 218:	9952                	add	s2,s2,s4
 21a:	ff2999e3          	bne	s3,s2,20c <threetest+0x10c>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 21e:	6a05                	lui	s4,0x1
        if(*(int*)q != getpid()){
 220:	0004a903          	lw	s2,0(s1)
 224:	00000097          	auipc	ra,0x0
 228:	5b6080e7          	jalr	1462(ra) # 7da <getpid>
 22c:	04a91763          	bne	s2,a0,27a <threetest+0x17a>
      for(char *q = p; q < p + (sz/5)*4; q += 4096){
 230:	94d2                	add	s1,s1,s4
 232:	fe9997e3          	bne	s3,s1,220 <threetest+0x120>
      exit(-1);
 236:	557d                	li	a0,-1
 238:	00000097          	auipc	ra,0x0
 23c:	522080e7          	jalr	1314(ra) # 75a <exit>
      printf("fork failed");
 240:	00001517          	auipc	a0,0x1
 244:	ae050513          	addi	a0,a0,-1312 # d20 <malloc+0x164>
 248:	00001097          	auipc	ra,0x1
 24c:	8bc080e7          	jalr	-1860(ra) # b04 <printf>
      exit(-1);
 250:	557d                	li	a0,-1
 252:	00000097          	auipc	ra,0x0
 256:	508080e7          	jalr	1288(ra) # 75a <exit>
    for(char *q = p; q < p + (sz/2); q += 4096){
 25a:	01000737          	lui	a4,0x1000
 25e:	9726                	add	a4,a4,s1
      *(int*)q = 9999;
 260:	6789                	lui	a5,0x2
 262:	70f78793          	addi	a5,a5,1807 # 270f <buf+0x6ff>
    for(char *q = p; q < p + (sz/2); q += 4096){
 266:	6685                	lui	a3,0x1
      *(int*)q = 9999;
 268:	c09c                	sw	a5,0(s1)
    for(char *q = p; q < p + (sz/2); q += 4096){
 26a:	94b6                	add	s1,s1,a3
 26c:	fee49ee3          	bne	s1,a4,268 <threetest+0x168>
    exit(0);
 270:	4501                	li	a0,0
 272:	00000097          	auipc	ra,0x0
 276:	4e8080e7          	jalr	1256(ra) # 75a <exit>
          printf("wrong content\n");
 27a:	00001517          	auipc	a0,0x1
 27e:	ab650513          	addi	a0,a0,-1354 # d30 <malloc+0x174>
 282:	00001097          	auipc	ra,0x1
 286:	882080e7          	jalr	-1918(ra) # b04 <printf>
          exit(-1);
 28a:	557d                	li	a0,-1
 28c:	00000097          	auipc	ra,0x0
 290:	4ce080e7          	jalr	1230(ra) # 75a <exit>
      printf("wrong content\n");
 294:	00001517          	auipc	a0,0x1
 298:	a9c50513          	addi	a0,a0,-1380 # d30 <malloc+0x174>
 29c:	00001097          	auipc	ra,0x1
 2a0:	868080e7          	jalr	-1944(ra) # b04 <printf>
      exit(-1);
 2a4:	557d                	li	a0,-1
 2a6:	00000097          	auipc	ra,0x0
 2aa:	4b4080e7          	jalr	1204(ra) # 75a <exit>
    printf("sbrk(-%d) failed\n", sz);
 2ae:	020005b7          	lui	a1,0x2000
 2b2:	00001517          	auipc	a0,0x1
 2b6:	a3650513          	addi	a0,a0,-1482 # ce8 <malloc+0x12c>
 2ba:	00001097          	auipc	ra,0x1
 2be:	84a080e7          	jalr	-1974(ra) # b04 <printf>
    exit(-1);
 2c2:	557d                	li	a0,-1
 2c4:	00000097          	auipc	ra,0x0
 2c8:	496080e7          	jalr	1174(ra) # 75a <exit>

00000000000002cc <filetest>:
char junk3[4096];

// test whether copyout() simulates COW faults.
void
filetest()
{
 2cc:	7179                	addi	sp,sp,-48
 2ce:	f406                	sd	ra,40(sp)
 2d0:	f022                	sd	s0,32(sp)
 2d2:	ec26                	sd	s1,24(sp)
 2d4:	e84a                	sd	s2,16(sp)
 2d6:	1800                	addi	s0,sp,48
  printf("file: ");
 2d8:	00001517          	auipc	a0,0x1
 2dc:	a6850513          	addi	a0,a0,-1432 # d40 <malloc+0x184>
 2e0:	00001097          	auipc	ra,0x1
 2e4:	824080e7          	jalr	-2012(ra) # b04 <printf>
  
  buf[0] = 99;
 2e8:	06300793          	li	a5,99
 2ec:	00002717          	auipc	a4,0x2
 2f0:	d2f70223          	sb	a5,-732(a4) # 2010 <buf>

  for(int i = 0; i < 4; i++){
 2f4:	fc042c23          	sw	zero,-40(s0)
    if(pipe(fds) != 0){
 2f8:	00001497          	auipc	s1,0x1
 2fc:	d0848493          	addi	s1,s1,-760 # 1000 <fds>
  for(int i = 0; i < 4; i++){
 300:	490d                	li	s2,3
    if(pipe(fds) != 0){
 302:	8526                	mv	a0,s1
 304:	00000097          	auipc	ra,0x0
 308:	466080e7          	jalr	1126(ra) # 76a <pipe>
 30c:	e149                	bnez	a0,38e <filetest+0xc2>
      printf("pipe() failed\n");
      exit(-1);
    }
    int pid = fork();
 30e:	00000097          	auipc	ra,0x0
 312:	444080e7          	jalr	1092(ra) # 752 <fork>
    if(pid < 0){
 316:	08054963          	bltz	a0,3a8 <filetest+0xdc>
      printf("fork failed\n");
      exit(-1);
    }
    if(pid == 0){
 31a:	c545                	beqz	a0,3c2 <filetest+0xf6>
        printf("error: read the wrong value\n");
        exit(1);
      }
      exit(0);
    }
    if(write(fds[1], &i, sizeof(i)) != sizeof(i)){
 31c:	4611                	li	a2,4
 31e:	fd840593          	addi	a1,s0,-40
 322:	40c8                	lw	a0,4(s1)
 324:	00000097          	auipc	ra,0x0
 328:	456080e7          	jalr	1110(ra) # 77a <write>
 32c:	4791                	li	a5,4
 32e:	10f51b63          	bne	a0,a5,444 <filetest+0x178>
  for(int i = 0; i < 4; i++){
 332:	fd842783          	lw	a5,-40(s0)
 336:	2785                	addiw	a5,a5,1
 338:	0007871b          	sext.w	a4,a5
 33c:	fcf42c23          	sw	a5,-40(s0)
 340:	fce951e3          	bge	s2,a4,302 <filetest+0x36>
      printf("error: write failed\n");
      exit(-1);
    }
  }

  int xstatus = 0;
 344:	fc042e23          	sw	zero,-36(s0)
 348:	4491                	li	s1,4
  for(int i = 0; i < 4; i++) {
    wait(&xstatus);
 34a:	fdc40513          	addi	a0,s0,-36
 34e:	00000097          	auipc	ra,0x0
 352:	414080e7          	jalr	1044(ra) # 762 <wait>
    if(xstatus != 0) {
 356:	fdc42783          	lw	a5,-36(s0)
 35a:	10079263          	bnez	a5,45e <filetest+0x192>
  for(int i = 0; i < 4; i++) {
 35e:	34fd                	addiw	s1,s1,-1
 360:	f4ed                	bnez	s1,34a <filetest+0x7e>
      exit(1);
    }
  }

  if(buf[0] != 99){
 362:	00002717          	auipc	a4,0x2
 366:	cae74703          	lbu	a4,-850(a4) # 2010 <buf>
 36a:	06300793          	li	a5,99
 36e:	0ef71d63          	bne	a4,a5,468 <filetest+0x19c>
    printf("error: child overwrote parent\n");
    exit(1);
  }

  printf("ok\n");
 372:	00001517          	auipc	a0,0x1
 376:	98e50513          	addi	a0,a0,-1650 # d00 <malloc+0x144>
 37a:	00000097          	auipc	ra,0x0
 37e:	78a080e7          	jalr	1930(ra) # b04 <printf>
}
 382:	70a2                	ld	ra,40(sp)
 384:	7402                	ld	s0,32(sp)
 386:	64e2                	ld	s1,24(sp)
 388:	6942                	ld	s2,16(sp)
 38a:	6145                	addi	sp,sp,48
 38c:	8082                	ret
      printf("pipe() failed\n");
 38e:	00001517          	auipc	a0,0x1
 392:	9ba50513          	addi	a0,a0,-1606 # d48 <malloc+0x18c>
 396:	00000097          	auipc	ra,0x0
 39a:	76e080e7          	jalr	1902(ra) # b04 <printf>
      exit(-1);
 39e:	557d                	li	a0,-1
 3a0:	00000097          	auipc	ra,0x0
 3a4:	3ba080e7          	jalr	954(ra) # 75a <exit>
      printf("fork failed\n");
 3a8:	00001517          	auipc	a0,0x1
 3ac:	96850513          	addi	a0,a0,-1688 # d10 <malloc+0x154>
 3b0:	00000097          	auipc	ra,0x0
 3b4:	754080e7          	jalr	1876(ra) # b04 <printf>
      exit(-1);
 3b8:	557d                	li	a0,-1
 3ba:	00000097          	auipc	ra,0x0
 3be:	3a0080e7          	jalr	928(ra) # 75a <exit>
      sleep(1);
 3c2:	4505                	li	a0,1
 3c4:	00000097          	auipc	ra,0x0
 3c8:	426080e7          	jalr	1062(ra) # 7ea <sleep>
      if(read(fds[0], buf, sizeof(i)) != sizeof(i)){
 3cc:	4611                	li	a2,4
 3ce:	00002597          	auipc	a1,0x2
 3d2:	c4258593          	addi	a1,a1,-958 # 2010 <buf>
 3d6:	00001517          	auipc	a0,0x1
 3da:	c2a52503          	lw	a0,-982(a0) # 1000 <fds>
 3de:	00000097          	auipc	ra,0x0
 3e2:	394080e7          	jalr	916(ra) # 772 <read>
 3e6:	4791                	li	a5,4
 3e8:	02f51c63          	bne	a0,a5,420 <filetest+0x154>
      sleep(1);
 3ec:	4505                	li	a0,1
 3ee:	00000097          	auipc	ra,0x0
 3f2:	3fc080e7          	jalr	1020(ra) # 7ea <sleep>
      if(j != i){
 3f6:	fd842703          	lw	a4,-40(s0)
 3fa:	00002797          	auipc	a5,0x2
 3fe:	c167a783          	lw	a5,-1002(a5) # 2010 <buf>
 402:	02f70c63          	beq	a4,a5,43a <filetest+0x16e>
        printf("error: read the wrong value\n");
 406:	00001517          	auipc	a0,0x1
 40a:	96a50513          	addi	a0,a0,-1686 # d70 <malloc+0x1b4>
 40e:	00000097          	auipc	ra,0x0
 412:	6f6080e7          	jalr	1782(ra) # b04 <printf>
        exit(1);
 416:	4505                	li	a0,1
 418:	00000097          	auipc	ra,0x0
 41c:	342080e7          	jalr	834(ra) # 75a <exit>
        printf("error: read failed\n");
 420:	00001517          	auipc	a0,0x1
 424:	93850513          	addi	a0,a0,-1736 # d58 <malloc+0x19c>
 428:	00000097          	auipc	ra,0x0
 42c:	6dc080e7          	jalr	1756(ra) # b04 <printf>
        exit(1);
 430:	4505                	li	a0,1
 432:	00000097          	auipc	ra,0x0
 436:	328080e7          	jalr	808(ra) # 75a <exit>
      exit(0);
 43a:	4501                	li	a0,0
 43c:	00000097          	auipc	ra,0x0
 440:	31e080e7          	jalr	798(ra) # 75a <exit>
      printf("error: write failed\n");
 444:	00001517          	auipc	a0,0x1
 448:	94c50513          	addi	a0,a0,-1716 # d90 <malloc+0x1d4>
 44c:	00000097          	auipc	ra,0x0
 450:	6b8080e7          	jalr	1720(ra) # b04 <printf>
      exit(-1);
 454:	557d                	li	a0,-1
 456:	00000097          	auipc	ra,0x0
 45a:	304080e7          	jalr	772(ra) # 75a <exit>
      exit(1);
 45e:	4505                	li	a0,1
 460:	00000097          	auipc	ra,0x0
 464:	2fa080e7          	jalr	762(ra) # 75a <exit>
    printf("error: child overwrote parent\n");
 468:	00001517          	auipc	a0,0x1
 46c:	94050513          	addi	a0,a0,-1728 # da8 <malloc+0x1ec>
 470:	00000097          	auipc	ra,0x0
 474:	694080e7          	jalr	1684(ra) # b04 <printf>
    exit(1);
 478:	4505                	li	a0,1
 47a:	00000097          	auipc	ra,0x0
 47e:	2e0080e7          	jalr	736(ra) # 75a <exit>

0000000000000482 <main>:

int
main(int argc, char *argv[])
{
 482:	1141                	addi	sp,sp,-16
 484:	e406                	sd	ra,8(sp)
 486:	e022                	sd	s0,0(sp)
 488:	0800                	addi	s0,sp,16
  simpletest();
 48a:	00000097          	auipc	ra,0x0
 48e:	b76080e7          	jalr	-1162(ra) # 0 <simpletest>

  // check that the first simpletest() freed the physical memory.
  simpletest();
 492:	00000097          	auipc	ra,0x0
 496:	b6e080e7          	jalr	-1170(ra) # 0 <simpletest>

  threetest();
 49a:	00000097          	auipc	ra,0x0
 49e:	c66080e7          	jalr	-922(ra) # 100 <threetest>
  threetest();
 4a2:	00000097          	auipc	ra,0x0
 4a6:	c5e080e7          	jalr	-930(ra) # 100 <threetest>
  threetest();
 4aa:	00000097          	auipc	ra,0x0
 4ae:	c56080e7          	jalr	-938(ra) # 100 <threetest>

  filetest();
 4b2:	00000097          	auipc	ra,0x0
 4b6:	e1a080e7          	jalr	-486(ra) # 2cc <filetest>

  printf("ALL COW TESTS PASSED\n");
 4ba:	00001517          	auipc	a0,0x1
 4be:	90e50513          	addi	a0,a0,-1778 # dc8 <malloc+0x20c>
 4c2:	00000097          	auipc	ra,0x0
 4c6:	642080e7          	jalr	1602(ra) # b04 <printf>

  exit(0);
 4ca:	4501                	li	a0,0
 4cc:	00000097          	auipc	ra,0x0
 4d0:	28e080e7          	jalr	654(ra) # 75a <exit>

00000000000004d4 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 4d4:	1141                	addi	sp,sp,-16
 4d6:	e406                	sd	ra,8(sp)
 4d8:	e022                	sd	s0,0(sp)
 4da:	0800                	addi	s0,sp,16
  extern int main();
  main();
 4dc:	00000097          	auipc	ra,0x0
 4e0:	fa6080e7          	jalr	-90(ra) # 482 <main>
  exit(0);
 4e4:	4501                	li	a0,0
 4e6:	00000097          	auipc	ra,0x0
 4ea:	274080e7          	jalr	628(ra) # 75a <exit>

00000000000004ee <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 4ee:	1141                	addi	sp,sp,-16
 4f0:	e422                	sd	s0,8(sp)
 4f2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 4f4:	87aa                	mv	a5,a0
 4f6:	0585                	addi	a1,a1,1
 4f8:	0785                	addi	a5,a5,1
 4fa:	fff5c703          	lbu	a4,-1(a1)
 4fe:	fee78fa3          	sb	a4,-1(a5)
 502:	fb75                	bnez	a4,4f6 <strcpy+0x8>
    ;
  return os;
}
 504:	6422                	ld	s0,8(sp)
 506:	0141                	addi	sp,sp,16
 508:	8082                	ret

000000000000050a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 50a:	1141                	addi	sp,sp,-16
 50c:	e422                	sd	s0,8(sp)
 50e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 510:	00054783          	lbu	a5,0(a0)
 514:	cb91                	beqz	a5,528 <strcmp+0x1e>
 516:	0005c703          	lbu	a4,0(a1)
 51a:	00f71763          	bne	a4,a5,528 <strcmp+0x1e>
    p++, q++;
 51e:	0505                	addi	a0,a0,1
 520:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 522:	00054783          	lbu	a5,0(a0)
 526:	fbe5                	bnez	a5,516 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 528:	0005c503          	lbu	a0,0(a1)
}
 52c:	40a7853b          	subw	a0,a5,a0
 530:	6422                	ld	s0,8(sp)
 532:	0141                	addi	sp,sp,16
 534:	8082                	ret

0000000000000536 <strlen>:

uint
strlen(const char *s)
{
 536:	1141                	addi	sp,sp,-16
 538:	e422                	sd	s0,8(sp)
 53a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 53c:	00054783          	lbu	a5,0(a0)
 540:	cf91                	beqz	a5,55c <strlen+0x26>
 542:	0505                	addi	a0,a0,1
 544:	87aa                	mv	a5,a0
 546:	4685                	li	a3,1
 548:	9e89                	subw	a3,a3,a0
 54a:	00f6853b          	addw	a0,a3,a5
 54e:	0785                	addi	a5,a5,1
 550:	fff7c703          	lbu	a4,-1(a5)
 554:	fb7d                	bnez	a4,54a <strlen+0x14>
    ;
  return n;
}
 556:	6422                	ld	s0,8(sp)
 558:	0141                	addi	sp,sp,16
 55a:	8082                	ret
  for(n = 0; s[n]; n++)
 55c:	4501                	li	a0,0
 55e:	bfe5                	j	556 <strlen+0x20>

0000000000000560 <memset>:

void*
memset(void *dst, int c, uint n)
{
 560:	1141                	addi	sp,sp,-16
 562:	e422                	sd	s0,8(sp)
 564:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 566:	ca19                	beqz	a2,57c <memset+0x1c>
 568:	87aa                	mv	a5,a0
 56a:	1602                	slli	a2,a2,0x20
 56c:	9201                	srli	a2,a2,0x20
 56e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 572:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 576:	0785                	addi	a5,a5,1
 578:	fee79de3          	bne	a5,a4,572 <memset+0x12>
  }
  return dst;
}
 57c:	6422                	ld	s0,8(sp)
 57e:	0141                	addi	sp,sp,16
 580:	8082                	ret

0000000000000582 <strchr>:

char*
strchr(const char *s, char c)
{
 582:	1141                	addi	sp,sp,-16
 584:	e422                	sd	s0,8(sp)
 586:	0800                	addi	s0,sp,16
  for(; *s; s++)
 588:	00054783          	lbu	a5,0(a0)
 58c:	cb99                	beqz	a5,5a2 <strchr+0x20>
    if(*s == c)
 58e:	00f58763          	beq	a1,a5,59c <strchr+0x1a>
  for(; *s; s++)
 592:	0505                	addi	a0,a0,1
 594:	00054783          	lbu	a5,0(a0)
 598:	fbfd                	bnez	a5,58e <strchr+0xc>
      return (char*)s;
  return 0;
 59a:	4501                	li	a0,0
}
 59c:	6422                	ld	s0,8(sp)
 59e:	0141                	addi	sp,sp,16
 5a0:	8082                	ret
  return 0;
 5a2:	4501                	li	a0,0
 5a4:	bfe5                	j	59c <strchr+0x1a>

00000000000005a6 <gets>:

char*
gets(char *buf, int max)
{
 5a6:	711d                	addi	sp,sp,-96
 5a8:	ec86                	sd	ra,88(sp)
 5aa:	e8a2                	sd	s0,80(sp)
 5ac:	e4a6                	sd	s1,72(sp)
 5ae:	e0ca                	sd	s2,64(sp)
 5b0:	fc4e                	sd	s3,56(sp)
 5b2:	f852                	sd	s4,48(sp)
 5b4:	f456                	sd	s5,40(sp)
 5b6:	f05a                	sd	s6,32(sp)
 5b8:	ec5e                	sd	s7,24(sp)
 5ba:	1080                	addi	s0,sp,96
 5bc:	8baa                	mv	s7,a0
 5be:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 5c0:	892a                	mv	s2,a0
 5c2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 5c4:	4aa9                	li	s5,10
 5c6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 5c8:	89a6                	mv	s3,s1
 5ca:	2485                	addiw	s1,s1,1
 5cc:	0344d863          	bge	s1,s4,5fc <gets+0x56>
    cc = read(0, &c, 1);
 5d0:	4605                	li	a2,1
 5d2:	faf40593          	addi	a1,s0,-81
 5d6:	4501                	li	a0,0
 5d8:	00000097          	auipc	ra,0x0
 5dc:	19a080e7          	jalr	410(ra) # 772 <read>
    if(cc < 1)
 5e0:	00a05e63          	blez	a0,5fc <gets+0x56>
    buf[i++] = c;
 5e4:	faf44783          	lbu	a5,-81(s0)
 5e8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 5ec:	01578763          	beq	a5,s5,5fa <gets+0x54>
 5f0:	0905                	addi	s2,s2,1
 5f2:	fd679be3          	bne	a5,s6,5c8 <gets+0x22>
  for(i=0; i+1 < max; ){
 5f6:	89a6                	mv	s3,s1
 5f8:	a011                	j	5fc <gets+0x56>
 5fa:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 5fc:	99de                	add	s3,s3,s7
 5fe:	00098023          	sb	zero,0(s3) # 199a000 <base+0x1994ff0>
  return buf;
}
 602:	855e                	mv	a0,s7
 604:	60e6                	ld	ra,88(sp)
 606:	6446                	ld	s0,80(sp)
 608:	64a6                	ld	s1,72(sp)
 60a:	6906                	ld	s2,64(sp)
 60c:	79e2                	ld	s3,56(sp)
 60e:	7a42                	ld	s4,48(sp)
 610:	7aa2                	ld	s5,40(sp)
 612:	7b02                	ld	s6,32(sp)
 614:	6be2                	ld	s7,24(sp)
 616:	6125                	addi	sp,sp,96
 618:	8082                	ret

000000000000061a <stat>:

int
stat(const char *n, struct stat *st)
{
 61a:	1101                	addi	sp,sp,-32
 61c:	ec06                	sd	ra,24(sp)
 61e:	e822                	sd	s0,16(sp)
 620:	e426                	sd	s1,8(sp)
 622:	e04a                	sd	s2,0(sp)
 624:	1000                	addi	s0,sp,32
 626:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 628:	4581                	li	a1,0
 62a:	00000097          	auipc	ra,0x0
 62e:	170080e7          	jalr	368(ra) # 79a <open>
  if(fd < 0)
 632:	02054563          	bltz	a0,65c <stat+0x42>
 636:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 638:	85ca                	mv	a1,s2
 63a:	00000097          	auipc	ra,0x0
 63e:	178080e7          	jalr	376(ra) # 7b2 <fstat>
 642:	892a                	mv	s2,a0
  close(fd);
 644:	8526                	mv	a0,s1
 646:	00000097          	auipc	ra,0x0
 64a:	13c080e7          	jalr	316(ra) # 782 <close>
  return r;
}
 64e:	854a                	mv	a0,s2
 650:	60e2                	ld	ra,24(sp)
 652:	6442                	ld	s0,16(sp)
 654:	64a2                	ld	s1,8(sp)
 656:	6902                	ld	s2,0(sp)
 658:	6105                	addi	sp,sp,32
 65a:	8082                	ret
    return -1;
 65c:	597d                	li	s2,-1
 65e:	bfc5                	j	64e <stat+0x34>

0000000000000660 <atoi>:

int
atoi(const char *s)
{
 660:	1141                	addi	sp,sp,-16
 662:	e422                	sd	s0,8(sp)
 664:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 666:	00054683          	lbu	a3,0(a0)
 66a:	fd06879b          	addiw	a5,a3,-48 # fd0 <digits+0x190>
 66e:	0ff7f793          	zext.b	a5,a5
 672:	4625                	li	a2,9
 674:	02f66863          	bltu	a2,a5,6a4 <atoi+0x44>
 678:	872a                	mv	a4,a0
  n = 0;
 67a:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 67c:	0705                	addi	a4,a4,1
 67e:	0025179b          	slliw	a5,a0,0x2
 682:	9fa9                	addw	a5,a5,a0
 684:	0017979b          	slliw	a5,a5,0x1
 688:	9fb5                	addw	a5,a5,a3
 68a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 68e:	00074683          	lbu	a3,0(a4)
 692:	fd06879b          	addiw	a5,a3,-48
 696:	0ff7f793          	zext.b	a5,a5
 69a:	fef671e3          	bgeu	a2,a5,67c <atoi+0x1c>
  return n;
}
 69e:	6422                	ld	s0,8(sp)
 6a0:	0141                	addi	sp,sp,16
 6a2:	8082                	ret
  n = 0;
 6a4:	4501                	li	a0,0
 6a6:	bfe5                	j	69e <atoi+0x3e>

00000000000006a8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 6a8:	1141                	addi	sp,sp,-16
 6aa:	e422                	sd	s0,8(sp)
 6ac:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 6ae:	02b57463          	bgeu	a0,a1,6d6 <memmove+0x2e>
    while(n-- > 0)
 6b2:	00c05f63          	blez	a2,6d0 <memmove+0x28>
 6b6:	1602                	slli	a2,a2,0x20
 6b8:	9201                	srli	a2,a2,0x20
 6ba:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 6be:	872a                	mv	a4,a0
      *dst++ = *src++;
 6c0:	0585                	addi	a1,a1,1
 6c2:	0705                	addi	a4,a4,1
 6c4:	fff5c683          	lbu	a3,-1(a1)
 6c8:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 6cc:	fee79ae3          	bne	a5,a4,6c0 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 6d0:	6422                	ld	s0,8(sp)
 6d2:	0141                	addi	sp,sp,16
 6d4:	8082                	ret
    dst += n;
 6d6:	00c50733          	add	a4,a0,a2
    src += n;
 6da:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 6dc:	fec05ae3          	blez	a2,6d0 <memmove+0x28>
 6e0:	fff6079b          	addiw	a5,a2,-1
 6e4:	1782                	slli	a5,a5,0x20
 6e6:	9381                	srli	a5,a5,0x20
 6e8:	fff7c793          	not	a5,a5
 6ec:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 6ee:	15fd                	addi	a1,a1,-1
 6f0:	177d                	addi	a4,a4,-1
 6f2:	0005c683          	lbu	a3,0(a1)
 6f6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 6fa:	fee79ae3          	bne	a5,a4,6ee <memmove+0x46>
 6fe:	bfc9                	j	6d0 <memmove+0x28>

0000000000000700 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 700:	1141                	addi	sp,sp,-16
 702:	e422                	sd	s0,8(sp)
 704:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 706:	ca05                	beqz	a2,736 <memcmp+0x36>
 708:	fff6069b          	addiw	a3,a2,-1
 70c:	1682                	slli	a3,a3,0x20
 70e:	9281                	srli	a3,a3,0x20
 710:	0685                	addi	a3,a3,1
 712:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 714:	00054783          	lbu	a5,0(a0)
 718:	0005c703          	lbu	a4,0(a1)
 71c:	00e79863          	bne	a5,a4,72c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 720:	0505                	addi	a0,a0,1
    p2++;
 722:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 724:	fed518e3          	bne	a0,a3,714 <memcmp+0x14>
  }
  return 0;
 728:	4501                	li	a0,0
 72a:	a019                	j	730 <memcmp+0x30>
      return *p1 - *p2;
 72c:	40e7853b          	subw	a0,a5,a4
}
 730:	6422                	ld	s0,8(sp)
 732:	0141                	addi	sp,sp,16
 734:	8082                	ret
  return 0;
 736:	4501                	li	a0,0
 738:	bfe5                	j	730 <memcmp+0x30>

000000000000073a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 73a:	1141                	addi	sp,sp,-16
 73c:	e406                	sd	ra,8(sp)
 73e:	e022                	sd	s0,0(sp)
 740:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 742:	00000097          	auipc	ra,0x0
 746:	f66080e7          	jalr	-154(ra) # 6a8 <memmove>
}
 74a:	60a2                	ld	ra,8(sp)
 74c:	6402                	ld	s0,0(sp)
 74e:	0141                	addi	sp,sp,16
 750:	8082                	ret

0000000000000752 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 752:	4885                	li	a7,1
 ecall
 754:	00000073          	ecall
 ret
 758:	8082                	ret

000000000000075a <exit>:
.global exit
exit:
 li a7, SYS_exit
 75a:	4889                	li	a7,2
 ecall
 75c:	00000073          	ecall
 ret
 760:	8082                	ret

0000000000000762 <wait>:
.global wait
wait:
 li a7, SYS_wait
 762:	488d                	li	a7,3
 ecall
 764:	00000073          	ecall
 ret
 768:	8082                	ret

000000000000076a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 76a:	4891                	li	a7,4
 ecall
 76c:	00000073          	ecall
 ret
 770:	8082                	ret

0000000000000772 <read>:
.global read
read:
 li a7, SYS_read
 772:	4895                	li	a7,5
 ecall
 774:	00000073          	ecall
 ret
 778:	8082                	ret

000000000000077a <write>:
.global write
write:
 li a7, SYS_write
 77a:	48c1                	li	a7,16
 ecall
 77c:	00000073          	ecall
 ret
 780:	8082                	ret

0000000000000782 <close>:
.global close
close:
 li a7, SYS_close
 782:	48d5                	li	a7,21
 ecall
 784:	00000073          	ecall
 ret
 788:	8082                	ret

000000000000078a <kill>:
.global kill
kill:
 li a7, SYS_kill
 78a:	4899                	li	a7,6
 ecall
 78c:	00000073          	ecall
 ret
 790:	8082                	ret

0000000000000792 <exec>:
.global exec
exec:
 li a7, SYS_exec
 792:	489d                	li	a7,7
 ecall
 794:	00000073          	ecall
 ret
 798:	8082                	ret

000000000000079a <open>:
.global open
open:
 li a7, SYS_open
 79a:	48bd                	li	a7,15
 ecall
 79c:	00000073          	ecall
 ret
 7a0:	8082                	ret

00000000000007a2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 7a2:	48c5                	li	a7,17
 ecall
 7a4:	00000073          	ecall
 ret
 7a8:	8082                	ret

00000000000007aa <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 7aa:	48c9                	li	a7,18
 ecall
 7ac:	00000073          	ecall
 ret
 7b0:	8082                	ret

00000000000007b2 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 7b2:	48a1                	li	a7,8
 ecall
 7b4:	00000073          	ecall
 ret
 7b8:	8082                	ret

00000000000007ba <link>:
.global link
link:
 li a7, SYS_link
 7ba:	48cd                	li	a7,19
 ecall
 7bc:	00000073          	ecall
 ret
 7c0:	8082                	ret

00000000000007c2 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 7c2:	48d1                	li	a7,20
 ecall
 7c4:	00000073          	ecall
 ret
 7c8:	8082                	ret

00000000000007ca <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 7ca:	48a5                	li	a7,9
 ecall
 7cc:	00000073          	ecall
 ret
 7d0:	8082                	ret

00000000000007d2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 7d2:	48a9                	li	a7,10
 ecall
 7d4:	00000073          	ecall
 ret
 7d8:	8082                	ret

00000000000007da <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 7da:	48ad                	li	a7,11
 ecall
 7dc:	00000073          	ecall
 ret
 7e0:	8082                	ret

00000000000007e2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 7e2:	48b1                	li	a7,12
 ecall
 7e4:	00000073          	ecall
 ret
 7e8:	8082                	ret

00000000000007ea <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 7ea:	48b5                	li	a7,13
 ecall
 7ec:	00000073          	ecall
 ret
 7f0:	8082                	ret

00000000000007f2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 7f2:	48b9                	li	a7,14
 ecall
 7f4:	00000073          	ecall
 ret
 7f8:	8082                	ret

00000000000007fa <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 7fa:	48d9                	li	a7,22
 ecall
 7fc:	00000073          	ecall
 ret
 800:	8082                	ret

0000000000000802 <trace>:
.global trace
trace:
 li a7, SYS_trace
 802:	48e5                	li	a7,25
 ecall
 804:	00000073          	ecall
 ret
 808:	8082                	ret

000000000000080a <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 80a:	48dd                	li	a7,23
 ecall
 80c:	00000073          	ecall
 ret
 810:	8082                	ret

0000000000000812 <set_tickets>:
.global set_tickets
set_tickets:
 li a7, SYS_set_tickets
 812:	48e1                	li	a7,24
 ecall
 814:	00000073          	ecall
 ret
 818:	8082                	ret

000000000000081a <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 81a:	48e9                	li	a7,26
 ecall
 81c:	00000073          	ecall
 ret
 820:	8082                	ret

0000000000000822 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 822:	48ed                	li	a7,27
 ecall
 824:	00000073          	ecall
 ret
 828:	8082                	ret

000000000000082a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 82a:	1101                	addi	sp,sp,-32
 82c:	ec06                	sd	ra,24(sp)
 82e:	e822                	sd	s0,16(sp)
 830:	1000                	addi	s0,sp,32
 832:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 836:	4605                	li	a2,1
 838:	fef40593          	addi	a1,s0,-17
 83c:	00000097          	auipc	ra,0x0
 840:	f3e080e7          	jalr	-194(ra) # 77a <write>
}
 844:	60e2                	ld	ra,24(sp)
 846:	6442                	ld	s0,16(sp)
 848:	6105                	addi	sp,sp,32
 84a:	8082                	ret

000000000000084c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 84c:	7139                	addi	sp,sp,-64
 84e:	fc06                	sd	ra,56(sp)
 850:	f822                	sd	s0,48(sp)
 852:	f426                	sd	s1,40(sp)
 854:	f04a                	sd	s2,32(sp)
 856:	ec4e                	sd	s3,24(sp)
 858:	0080                	addi	s0,sp,64
 85a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 85c:	c299                	beqz	a3,862 <printint+0x16>
 85e:	0805c963          	bltz	a1,8f0 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 862:	2581                	sext.w	a1,a1
  neg = 0;
 864:	4881                	li	a7,0
 866:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 86a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 86c:	2601                	sext.w	a2,a2
 86e:	00000517          	auipc	a0,0x0
 872:	5d250513          	addi	a0,a0,1490 # e40 <digits>
 876:	883a                	mv	a6,a4
 878:	2705                	addiw	a4,a4,1
 87a:	02c5f7bb          	remuw	a5,a1,a2
 87e:	1782                	slli	a5,a5,0x20
 880:	9381                	srli	a5,a5,0x20
 882:	97aa                	add	a5,a5,a0
 884:	0007c783          	lbu	a5,0(a5)
 888:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 88c:	0005879b          	sext.w	a5,a1
 890:	02c5d5bb          	divuw	a1,a1,a2
 894:	0685                	addi	a3,a3,1
 896:	fec7f0e3          	bgeu	a5,a2,876 <printint+0x2a>
  if(neg)
 89a:	00088c63          	beqz	a7,8b2 <printint+0x66>
    buf[i++] = '-';
 89e:	fd070793          	addi	a5,a4,-48
 8a2:	00878733          	add	a4,a5,s0
 8a6:	02d00793          	li	a5,45
 8aa:	fef70823          	sb	a5,-16(a4)
 8ae:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 8b2:	02e05863          	blez	a4,8e2 <printint+0x96>
 8b6:	fc040793          	addi	a5,s0,-64
 8ba:	00e78933          	add	s2,a5,a4
 8be:	fff78993          	addi	s3,a5,-1
 8c2:	99ba                	add	s3,s3,a4
 8c4:	377d                	addiw	a4,a4,-1
 8c6:	1702                	slli	a4,a4,0x20
 8c8:	9301                	srli	a4,a4,0x20
 8ca:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 8ce:	fff94583          	lbu	a1,-1(s2)
 8d2:	8526                	mv	a0,s1
 8d4:	00000097          	auipc	ra,0x0
 8d8:	f56080e7          	jalr	-170(ra) # 82a <putc>
  while(--i >= 0)
 8dc:	197d                	addi	s2,s2,-1
 8de:	ff3918e3          	bne	s2,s3,8ce <printint+0x82>
}
 8e2:	70e2                	ld	ra,56(sp)
 8e4:	7442                	ld	s0,48(sp)
 8e6:	74a2                	ld	s1,40(sp)
 8e8:	7902                	ld	s2,32(sp)
 8ea:	69e2                	ld	s3,24(sp)
 8ec:	6121                	addi	sp,sp,64
 8ee:	8082                	ret
    x = -xx;
 8f0:	40b005bb          	negw	a1,a1
    neg = 1;
 8f4:	4885                	li	a7,1
    x = -xx;
 8f6:	bf85                	j	866 <printint+0x1a>

00000000000008f8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 8f8:	7119                	addi	sp,sp,-128
 8fa:	fc86                	sd	ra,120(sp)
 8fc:	f8a2                	sd	s0,112(sp)
 8fe:	f4a6                	sd	s1,104(sp)
 900:	f0ca                	sd	s2,96(sp)
 902:	ecce                	sd	s3,88(sp)
 904:	e8d2                	sd	s4,80(sp)
 906:	e4d6                	sd	s5,72(sp)
 908:	e0da                	sd	s6,64(sp)
 90a:	fc5e                	sd	s7,56(sp)
 90c:	f862                	sd	s8,48(sp)
 90e:	f466                	sd	s9,40(sp)
 910:	f06a                	sd	s10,32(sp)
 912:	ec6e                	sd	s11,24(sp)
 914:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 916:	0005c903          	lbu	s2,0(a1)
 91a:	18090f63          	beqz	s2,ab8 <vprintf+0x1c0>
 91e:	8aaa                	mv	s5,a0
 920:	8b32                	mv	s6,a2
 922:	00158493          	addi	s1,a1,1
  state = 0;
 926:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 928:	02500a13          	li	s4,37
 92c:	4c55                	li	s8,21
 92e:	00000c97          	auipc	s9,0x0
 932:	4bac8c93          	addi	s9,s9,1210 # de8 <malloc+0x22c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 936:	02800d93          	li	s11,40
  putc(fd, 'x');
 93a:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 93c:	00000b97          	auipc	s7,0x0
 940:	504b8b93          	addi	s7,s7,1284 # e40 <digits>
 944:	a839                	j	962 <vprintf+0x6a>
        putc(fd, c);
 946:	85ca                	mv	a1,s2
 948:	8556                	mv	a0,s5
 94a:	00000097          	auipc	ra,0x0
 94e:	ee0080e7          	jalr	-288(ra) # 82a <putc>
 952:	a019                	j	958 <vprintf+0x60>
    } else if(state == '%'){
 954:	01498d63          	beq	s3,s4,96e <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 958:	0485                	addi	s1,s1,1
 95a:	fff4c903          	lbu	s2,-1(s1)
 95e:	14090d63          	beqz	s2,ab8 <vprintf+0x1c0>
    if(state == 0){
 962:	fe0999e3          	bnez	s3,954 <vprintf+0x5c>
      if(c == '%'){
 966:	ff4910e3          	bne	s2,s4,946 <vprintf+0x4e>
        state = '%';
 96a:	89d2                	mv	s3,s4
 96c:	b7f5                	j	958 <vprintf+0x60>
      if(c == 'd'){
 96e:	11490c63          	beq	s2,s4,a86 <vprintf+0x18e>
 972:	f9d9079b          	addiw	a5,s2,-99
 976:	0ff7f793          	zext.b	a5,a5
 97a:	10fc6e63          	bltu	s8,a5,a96 <vprintf+0x19e>
 97e:	f9d9079b          	addiw	a5,s2,-99
 982:	0ff7f713          	zext.b	a4,a5
 986:	10ec6863          	bltu	s8,a4,a96 <vprintf+0x19e>
 98a:	00271793          	slli	a5,a4,0x2
 98e:	97e6                	add	a5,a5,s9
 990:	439c                	lw	a5,0(a5)
 992:	97e6                	add	a5,a5,s9
 994:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 996:	008b0913          	addi	s2,s6,8
 99a:	4685                	li	a3,1
 99c:	4629                	li	a2,10
 99e:	000b2583          	lw	a1,0(s6)
 9a2:	8556                	mv	a0,s5
 9a4:	00000097          	auipc	ra,0x0
 9a8:	ea8080e7          	jalr	-344(ra) # 84c <printint>
 9ac:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 9ae:	4981                	li	s3,0
 9b0:	b765                	j	958 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 9b2:	008b0913          	addi	s2,s6,8
 9b6:	4681                	li	a3,0
 9b8:	4629                	li	a2,10
 9ba:	000b2583          	lw	a1,0(s6)
 9be:	8556                	mv	a0,s5
 9c0:	00000097          	auipc	ra,0x0
 9c4:	e8c080e7          	jalr	-372(ra) # 84c <printint>
 9c8:	8b4a                	mv	s6,s2
      state = 0;
 9ca:	4981                	li	s3,0
 9cc:	b771                	j	958 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 9ce:	008b0913          	addi	s2,s6,8
 9d2:	4681                	li	a3,0
 9d4:	866a                	mv	a2,s10
 9d6:	000b2583          	lw	a1,0(s6)
 9da:	8556                	mv	a0,s5
 9dc:	00000097          	auipc	ra,0x0
 9e0:	e70080e7          	jalr	-400(ra) # 84c <printint>
 9e4:	8b4a                	mv	s6,s2
      state = 0;
 9e6:	4981                	li	s3,0
 9e8:	bf85                	j	958 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 9ea:	008b0793          	addi	a5,s6,8
 9ee:	f8f43423          	sd	a5,-120(s0)
 9f2:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 9f6:	03000593          	li	a1,48
 9fa:	8556                	mv	a0,s5
 9fc:	00000097          	auipc	ra,0x0
 a00:	e2e080e7          	jalr	-466(ra) # 82a <putc>
  putc(fd, 'x');
 a04:	07800593          	li	a1,120
 a08:	8556                	mv	a0,s5
 a0a:	00000097          	auipc	ra,0x0
 a0e:	e20080e7          	jalr	-480(ra) # 82a <putc>
 a12:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a14:	03c9d793          	srli	a5,s3,0x3c
 a18:	97de                	add	a5,a5,s7
 a1a:	0007c583          	lbu	a1,0(a5)
 a1e:	8556                	mv	a0,s5
 a20:	00000097          	auipc	ra,0x0
 a24:	e0a080e7          	jalr	-502(ra) # 82a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a28:	0992                	slli	s3,s3,0x4
 a2a:	397d                	addiw	s2,s2,-1
 a2c:	fe0914e3          	bnez	s2,a14 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 a30:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 a34:	4981                	li	s3,0
 a36:	b70d                	j	958 <vprintf+0x60>
        s = va_arg(ap, char*);
 a38:	008b0913          	addi	s2,s6,8
 a3c:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 a40:	02098163          	beqz	s3,a62 <vprintf+0x16a>
        while(*s != 0){
 a44:	0009c583          	lbu	a1,0(s3)
 a48:	c5ad                	beqz	a1,ab2 <vprintf+0x1ba>
          putc(fd, *s);
 a4a:	8556                	mv	a0,s5
 a4c:	00000097          	auipc	ra,0x0
 a50:	dde080e7          	jalr	-546(ra) # 82a <putc>
          s++;
 a54:	0985                	addi	s3,s3,1
        while(*s != 0){
 a56:	0009c583          	lbu	a1,0(s3)
 a5a:	f9e5                	bnez	a1,a4a <vprintf+0x152>
        s = va_arg(ap, char*);
 a5c:	8b4a                	mv	s6,s2
      state = 0;
 a5e:	4981                	li	s3,0
 a60:	bde5                	j	958 <vprintf+0x60>
          s = "(null)";
 a62:	00000997          	auipc	s3,0x0
 a66:	37e98993          	addi	s3,s3,894 # de0 <malloc+0x224>
        while(*s != 0){
 a6a:	85ee                	mv	a1,s11
 a6c:	bff9                	j	a4a <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 a6e:	008b0913          	addi	s2,s6,8
 a72:	000b4583          	lbu	a1,0(s6)
 a76:	8556                	mv	a0,s5
 a78:	00000097          	auipc	ra,0x0
 a7c:	db2080e7          	jalr	-590(ra) # 82a <putc>
 a80:	8b4a                	mv	s6,s2
      state = 0;
 a82:	4981                	li	s3,0
 a84:	bdd1                	j	958 <vprintf+0x60>
        putc(fd, c);
 a86:	85d2                	mv	a1,s4
 a88:	8556                	mv	a0,s5
 a8a:	00000097          	auipc	ra,0x0
 a8e:	da0080e7          	jalr	-608(ra) # 82a <putc>
      state = 0;
 a92:	4981                	li	s3,0
 a94:	b5d1                	j	958 <vprintf+0x60>
        putc(fd, '%');
 a96:	85d2                	mv	a1,s4
 a98:	8556                	mv	a0,s5
 a9a:	00000097          	auipc	ra,0x0
 a9e:	d90080e7          	jalr	-624(ra) # 82a <putc>
        putc(fd, c);
 aa2:	85ca                	mv	a1,s2
 aa4:	8556                	mv	a0,s5
 aa6:	00000097          	auipc	ra,0x0
 aaa:	d84080e7          	jalr	-636(ra) # 82a <putc>
      state = 0;
 aae:	4981                	li	s3,0
 ab0:	b565                	j	958 <vprintf+0x60>
        s = va_arg(ap, char*);
 ab2:	8b4a                	mv	s6,s2
      state = 0;
 ab4:	4981                	li	s3,0
 ab6:	b54d                	j	958 <vprintf+0x60>
    }
  }
}
 ab8:	70e6                	ld	ra,120(sp)
 aba:	7446                	ld	s0,112(sp)
 abc:	74a6                	ld	s1,104(sp)
 abe:	7906                	ld	s2,96(sp)
 ac0:	69e6                	ld	s3,88(sp)
 ac2:	6a46                	ld	s4,80(sp)
 ac4:	6aa6                	ld	s5,72(sp)
 ac6:	6b06                	ld	s6,64(sp)
 ac8:	7be2                	ld	s7,56(sp)
 aca:	7c42                	ld	s8,48(sp)
 acc:	7ca2                	ld	s9,40(sp)
 ace:	7d02                	ld	s10,32(sp)
 ad0:	6de2                	ld	s11,24(sp)
 ad2:	6109                	addi	sp,sp,128
 ad4:	8082                	ret

0000000000000ad6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 ad6:	715d                	addi	sp,sp,-80
 ad8:	ec06                	sd	ra,24(sp)
 ada:	e822                	sd	s0,16(sp)
 adc:	1000                	addi	s0,sp,32
 ade:	e010                	sd	a2,0(s0)
 ae0:	e414                	sd	a3,8(s0)
 ae2:	e818                	sd	a4,16(s0)
 ae4:	ec1c                	sd	a5,24(s0)
 ae6:	03043023          	sd	a6,32(s0)
 aea:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 aee:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 af2:	8622                	mv	a2,s0
 af4:	00000097          	auipc	ra,0x0
 af8:	e04080e7          	jalr	-508(ra) # 8f8 <vprintf>
}
 afc:	60e2                	ld	ra,24(sp)
 afe:	6442                	ld	s0,16(sp)
 b00:	6161                	addi	sp,sp,80
 b02:	8082                	ret

0000000000000b04 <printf>:

void
printf(const char *fmt, ...)
{
 b04:	711d                	addi	sp,sp,-96
 b06:	ec06                	sd	ra,24(sp)
 b08:	e822                	sd	s0,16(sp)
 b0a:	1000                	addi	s0,sp,32
 b0c:	e40c                	sd	a1,8(s0)
 b0e:	e810                	sd	a2,16(s0)
 b10:	ec14                	sd	a3,24(s0)
 b12:	f018                	sd	a4,32(s0)
 b14:	f41c                	sd	a5,40(s0)
 b16:	03043823          	sd	a6,48(s0)
 b1a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b1e:	00840613          	addi	a2,s0,8
 b22:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b26:	85aa                	mv	a1,a0
 b28:	4505                	li	a0,1
 b2a:	00000097          	auipc	ra,0x0
 b2e:	dce080e7          	jalr	-562(ra) # 8f8 <vprintf>
}
 b32:	60e2                	ld	ra,24(sp)
 b34:	6442                	ld	s0,16(sp)
 b36:	6125                	addi	sp,sp,96
 b38:	8082                	ret

0000000000000b3a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b3a:	1141                	addi	sp,sp,-16
 b3c:	e422                	sd	s0,8(sp)
 b3e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b40:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b44:	00000797          	auipc	a5,0x0
 b48:	4c47b783          	ld	a5,1220(a5) # 1008 <freep>
 b4c:	a02d                	j	b76 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b4e:	4618                	lw	a4,8(a2)
 b50:	9f2d                	addw	a4,a4,a1
 b52:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b56:	6398                	ld	a4,0(a5)
 b58:	6310                	ld	a2,0(a4)
 b5a:	a83d                	j	b98 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b5c:	ff852703          	lw	a4,-8(a0)
 b60:	9f31                	addw	a4,a4,a2
 b62:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 b64:	ff053683          	ld	a3,-16(a0)
 b68:	a091                	j	bac <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b6a:	6398                	ld	a4,0(a5)
 b6c:	00e7e463          	bltu	a5,a4,b74 <free+0x3a>
 b70:	00e6ea63          	bltu	a3,a4,b84 <free+0x4a>
{
 b74:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b76:	fed7fae3          	bgeu	a5,a3,b6a <free+0x30>
 b7a:	6398                	ld	a4,0(a5)
 b7c:	00e6e463          	bltu	a3,a4,b84 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b80:	fee7eae3          	bltu	a5,a4,b74 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 b84:	ff852583          	lw	a1,-8(a0)
 b88:	6390                	ld	a2,0(a5)
 b8a:	02059813          	slli	a6,a1,0x20
 b8e:	01c85713          	srli	a4,a6,0x1c
 b92:	9736                	add	a4,a4,a3
 b94:	fae60de3          	beq	a2,a4,b4e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 b98:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 b9c:	4790                	lw	a2,8(a5)
 b9e:	02061593          	slli	a1,a2,0x20
 ba2:	01c5d713          	srli	a4,a1,0x1c
 ba6:	973e                	add	a4,a4,a5
 ba8:	fae68ae3          	beq	a3,a4,b5c <free+0x22>
    p->s.ptr = bp->s.ptr;
 bac:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 bae:	00000717          	auipc	a4,0x0
 bb2:	44f73d23          	sd	a5,1114(a4) # 1008 <freep>
}
 bb6:	6422                	ld	s0,8(sp)
 bb8:	0141                	addi	sp,sp,16
 bba:	8082                	ret

0000000000000bbc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 bbc:	7139                	addi	sp,sp,-64
 bbe:	fc06                	sd	ra,56(sp)
 bc0:	f822                	sd	s0,48(sp)
 bc2:	f426                	sd	s1,40(sp)
 bc4:	f04a                	sd	s2,32(sp)
 bc6:	ec4e                	sd	s3,24(sp)
 bc8:	e852                	sd	s4,16(sp)
 bca:	e456                	sd	s5,8(sp)
 bcc:	e05a                	sd	s6,0(sp)
 bce:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 bd0:	02051493          	slli	s1,a0,0x20
 bd4:	9081                	srli	s1,s1,0x20
 bd6:	04bd                	addi	s1,s1,15
 bd8:	8091                	srli	s1,s1,0x4
 bda:	0014899b          	addiw	s3,s1,1
 bde:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 be0:	00000517          	auipc	a0,0x0
 be4:	42853503          	ld	a0,1064(a0) # 1008 <freep>
 be8:	c515                	beqz	a0,c14 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bea:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bec:	4798                	lw	a4,8(a5)
 bee:	02977f63          	bgeu	a4,s1,c2c <malloc+0x70>
 bf2:	8a4e                	mv	s4,s3
 bf4:	0009871b          	sext.w	a4,s3
 bf8:	6685                	lui	a3,0x1
 bfa:	00d77363          	bgeu	a4,a3,c00 <malloc+0x44>
 bfe:	6a05                	lui	s4,0x1
 c00:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 c04:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c08:	00000917          	auipc	s2,0x0
 c0c:	40090913          	addi	s2,s2,1024 # 1008 <freep>
  if(p == (char*)-1)
 c10:	5afd                	li	s5,-1
 c12:	a895                	j	c86 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 c14:	00004797          	auipc	a5,0x4
 c18:	3fc78793          	addi	a5,a5,1020 # 5010 <base>
 c1c:	00000717          	auipc	a4,0x0
 c20:	3ef73623          	sd	a5,1004(a4) # 1008 <freep>
 c24:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c26:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c2a:	b7e1                	j	bf2 <malloc+0x36>
      if(p->s.size == nunits)
 c2c:	02e48c63          	beq	s1,a4,c64 <malloc+0xa8>
        p->s.size -= nunits;
 c30:	4137073b          	subw	a4,a4,s3
 c34:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c36:	02071693          	slli	a3,a4,0x20
 c3a:	01c6d713          	srli	a4,a3,0x1c
 c3e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c40:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c44:	00000717          	auipc	a4,0x0
 c48:	3ca73223          	sd	a0,964(a4) # 1008 <freep>
      return (void*)(p + 1);
 c4c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c50:	70e2                	ld	ra,56(sp)
 c52:	7442                	ld	s0,48(sp)
 c54:	74a2                	ld	s1,40(sp)
 c56:	7902                	ld	s2,32(sp)
 c58:	69e2                	ld	s3,24(sp)
 c5a:	6a42                	ld	s4,16(sp)
 c5c:	6aa2                	ld	s5,8(sp)
 c5e:	6b02                	ld	s6,0(sp)
 c60:	6121                	addi	sp,sp,64
 c62:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c64:	6398                	ld	a4,0(a5)
 c66:	e118                	sd	a4,0(a0)
 c68:	bff1                	j	c44 <malloc+0x88>
  hp->s.size = nu;
 c6a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 c6e:	0541                	addi	a0,a0,16
 c70:	00000097          	auipc	ra,0x0
 c74:	eca080e7          	jalr	-310(ra) # b3a <free>
  return freep;
 c78:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 c7c:	d971                	beqz	a0,c50 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c7e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c80:	4798                	lw	a4,8(a5)
 c82:	fa9775e3          	bgeu	a4,s1,c2c <malloc+0x70>
    if(p == freep)
 c86:	00093703          	ld	a4,0(s2)
 c8a:	853e                	mv	a0,a5
 c8c:	fef719e3          	bne	a4,a5,c7e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 c90:	8552                	mv	a0,s4
 c92:	00000097          	auipc	ra,0x0
 c96:	b50080e7          	jalr	-1200(ra) # 7e2 <sbrk>
  if(p == (char*)-1)
 c9a:	fd5518e3          	bne	a0,s5,c6a <malloc+0xae>
        return 0;
 c9e:	4501                	li	a0,0
 ca0:	bf45                	j	c50 <malloc+0x94>
