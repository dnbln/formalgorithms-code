pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with sys_utypes_uuintptr_t_h;
with sys_utypes_uint16_t_h;
with utypes_uuint16_t_h;
with utypes_uuint32_t_h;
with sys_utypes_uintptr_t_h;
with System;
with utypes_uuint64_t_h;
with sys_utypes_uint64_t_h;

package sys_event_h is

   EVFILT_READ : constant := (-1);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:66
   EVFILT_WRITE : constant := (-2);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:67
   EVFILT_AIO : constant := (-3);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:68
   EVFILT_VNODE : constant := (-4);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:69
   EVFILT_PROC : constant := (-5);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:70
   EVFILT_SIGNAL : constant := (-6);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:71
   EVFILT_TIMER : constant := (-7);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:72
   EVFILT_MACHPORT : constant := (-8);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:73
   EVFILT_FS : constant := (-9);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:74
   EVFILT_USER : constant := (-10);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:75
   EVFILT_VM : constant := (-12);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:76
   EVFILT_EXCEPT : constant := (-15);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:77

   EVFILT_SYSCOUNT : constant := 17;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:79
   --  unsupported macro: EVFILT_THREADMARKER EVFILT_SYSCOUNT
   --  arg-macro: procedure EV_SET (kevp, a, b, c, d, e, f)
   --    do { struct kevent *__kevp__ := (kevp); __kevp__.ident := (a); __kevp__.filter := (b); __kevp__.flags := (c); __kevp__.fflags := (d); __kevp__.data := (e); __kevp__.udata := (f); } while(0)
   --  arg-macro: procedure EV_SET64 (kevp, a, b, c, d, e, f, g, h)
   --    do { struct kevent64_s *__kevp__ := (kevp); __kevp__.ident := (a); __kevp__.filter := (b); __kevp__.flags := (c); __kevp__.fflags := (d); __kevp__.data := (e); __kevp__.udata := (f); __kevp__.ext(0) := (g); __kevp__.ext(1) := (h); } while(0)

   KEVENT_FLAG_NONE : constant := 16#000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:131
   KEVENT_FLAG_IMMEDIATE : constant := 16#000001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:132
   KEVENT_FLAG_ERROR_EVENTS : constant := 16#000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:133

   EV_ADD : constant := 16#0001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:137
   EV_DELETE : constant := 16#0002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:138
   EV_ENABLE : constant := 16#0004#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:139
   EV_DISABLE : constant := 16#0008#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:140

   EV_ONESHOT : constant := 16#0010#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:143
   EV_CLEAR : constant := 16#0020#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:144
   EV_RECEIPT : constant := 16#0040#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:145

   EV_DISPATCH : constant := 16#0080#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:150
   EV_UDATA_SPECIFIC : constant := 16#0100#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:151
   --  unsupported macro: EV_DISPATCH2 (EV_DISPATCH | EV_UDATA_SPECIFIC)

   EV_VANISHED : constant := 16#0200#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:159

   EV_SYSFLAGS : constant := 16#F000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:162
   EV_FLAG0 : constant := 16#1000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:163
   EV_FLAG1 : constant := 16#2000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:164

   EV_EOF : constant := 16#8000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:167
   EV_ERROR : constant := 16#4000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:168
   --  unsupported macro: EV_POLL EV_FLAG0
   --  unsupported macro: EV_OOBAND EV_FLAG1

   NOTE_TRIGGER : constant := 16#01000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:205

   NOTE_FFNOP : constant := 16#00000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:214
   NOTE_FFAND : constant := 16#40000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:215
   NOTE_FFOR : constant := 16#80000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:216
   NOTE_FFCOPY : constant := 16#c0000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:217
   NOTE_FFCTRLMASK : constant := 16#c0000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:218
   NOTE_FFLAGSMASK : constant := 16#00ffffff#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:219

   NOTE_LOWAT : constant := 16#00000001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:228

   NOTE_OOB : constant := 16#00000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:231

   NOTE_DELETE : constant := 16#00000001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:236
   NOTE_WRITE : constant := 16#00000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:237
   NOTE_EXTEND : constant := 16#00000004#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:238
   NOTE_ATTRIB : constant := 16#00000008#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:239
   NOTE_LINK : constant := 16#00000010#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:240
   NOTE_RENAME : constant := 16#00000020#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:241
   NOTE_REVOKE : constant := 16#00000040#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:242
   NOTE_NONE : constant := 16#00000080#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:243
   NOTE_FUNLOCK : constant := 16#00000100#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:244

   NOTE_EXIT : constant := 16#80000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:260
   NOTE_FORK : constant := 16#40000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:261
   NOTE_EXEC : constant := 16#20000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:262
   --  unsupported macro: NOTE_REAP ((unsigned int)eNoteReapDeprecated )

   NOTE_SIGNAL : constant := 16#08000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:264
   NOTE_EXITSTATUS : constant := 16#04000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:265
   NOTE_EXIT_DETAIL : constant := 16#02000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:266

   NOTE_PDATAMASK : constant := 16#000fffff#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:268
   --  unsupported macro: NOTE_PCTRLMASK (~NOTE_PDATAMASK)
   --  unsupported macro: NOTE_EXIT_REPARENTED ((unsigned int)eNoteExitReparentedDeprecated)

   NOTE_EXIT_DETAIL_MASK : constant := 16#00070000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:282
   NOTE_EXIT_DECRYPTFAIL : constant := 16#00010000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:283
   NOTE_EXIT_MEMORY : constant := 16#00020000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:284
   NOTE_EXIT_CSERROR : constant := 16#00040000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:285

   NOTE_VM_PRESSURE : constant := 16#80000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:291
   NOTE_VM_PRESSURE_TERMINATE : constant := 16#40000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:292

   NOTE_VM_ERROR : constant := 16#10000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:294

   NOTE_SECONDS : constant := 16#00000001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:304
   NOTE_USECONDS : constant := 16#00000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:305
   NOTE_NSECONDS : constant := 16#00000004#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:306
   NOTE_ABSOLUTE : constant := 16#00000008#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:307

   NOTE_LEEWAY : constant := 16#00000010#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:309
   NOTE_CRITICAL : constant := 16#00000020#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:310
   NOTE_BACKGROUND : constant := 16#00000040#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:311
   NOTE_MACH_CONTINUOUS_TIME : constant := 16#00000080#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:312

   NOTE_MACHTIME : constant := 16#00000100#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:320

   NOTE_TRACK : constant := 16#00000001#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:362
   NOTE_TRACKERR : constant := 16#00000002#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:363
   NOTE_CHILD : constant := 16#00000004#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:364

   NOTE_VM_PRESSURE_SUDDEN_TERMINATE : constant := 16#20000000#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:293

  -- * Copyright (c) 2003-2019 Apple Inc. All rights reserved.
  -- *
  -- * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
  -- *
  -- * This file contains Original Code and/or Modifications of Original Code
  -- * as defined in and that are subject to the Apple Public Source License
  -- * Version 2.0 (the 'License'). You may not use this file except in
  -- * compliance with the License. The rights granted to you under the License
  -- * may not be used to create, or enable the creation or redistribution of,
  -- * unlawful or unlicensed copies of an Apple operating system, or to
  -- * circumvent, violate, or enable the circumvention or violation of, any
  -- * terms of an Apple operating system software license agreement.
  -- *
  -- * Please obtain a copy of the License at
  -- * http://www.opensource.apple.com/apsl/ and read it before using this file.
  -- *
  -- * The Original Code and all software distributed under the License are
  -- * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
  -- * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
  -- * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
  -- * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
  -- * Please see the License for the specific language governing rights and
  -- * limitations under the License.
  -- *
  -- * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
  --  

  ---
  -- * Copyright (c) 1999,2000,2001 Jonathan Lemon <jlemon@FreeBSD.org>
  -- * All rights reserved.
  -- *
  -- * Redistribution and use in source and binary forms, with or without
  -- * modification, are permitted provided that the following conditions
  -- * are met:
  -- * 1. Redistributions of source code must retain the above copyright
  -- *    notice, this list of conditions and the following disclaimer.
  -- * 2. Redistributions in binary form must reproduce the above copyright
  -- *    notice, this list of conditions and the following disclaimer in the
  -- *    documentation and/or other materials provided with the distribution.
  -- *
  -- * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
  -- * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  -- * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  -- * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
  -- * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  -- * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  -- * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  -- * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  -- * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  -- * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  -- * SUCH DAMAGE.
  -- *
  -- *	$FreeBSD: src/sys/sys/event.h,v 1.5.2.5 2001/12/14 19:21:22 jlemon Exp $
  --  

  -- * Filter types
  --  

  -- identifier for this event  
   type kevent is record
      ident : aliased sys_utypes_uuintptr_t_h.uintptr_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:85
      filter : aliased sys_utypes_uint16_t_h.int16_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:86
      flags : aliased utypes_uuint16_t_h.uint16_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:87
      fflags : aliased utypes_uuint32_t_h.uint32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:88
      data : aliased sys_utypes_uintptr_t_h.intptr_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:89
      udata : System.Address;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:90
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:84

  -- filter for event  
  -- general flags  
  -- filter-specific flags  
  -- filter-specific data  
  -- opaque user data identifier  
  -- identifier for this event  
   type anon_array1104 is array (0 .. 1) of aliased utypes_uuint64_t_h.uint64_t;
   type kevent64_s is record
      ident : aliased utypes_uuint64_t_h.uint64_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:97
      filter : aliased sys_utypes_uint16_t_h.int16_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:98
      flags : aliased utypes_uuint16_t_h.uint16_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:99
      fflags : aliased utypes_uuint32_t_h.uint32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:100
      data : aliased sys_utypes_uint64_t_h.int64_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:101
      udata : aliased utypes_uuint64_t_h.uint64_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:102
      ext : aliased anon_array1104;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:103
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:96

  -- filter for event  
  -- general flags  
  -- filter-specific flags  
  -- filter-specific data  
  -- opaque user data identifier  
  -- filter-specific extensions  
  -- kevent system call flags  
  -- actions  
  -- flags  
  -- ... with or without EV_ERROR  
  -- ... use KEVENT_FLAG_ERROR_EVENTS  
  --     on syscalls supporting flags  
  -- ... in combination with EV_DELETE  
  -- will defer delete until udata-specific  
  -- event enabled. EINPROGRESS will be  
  -- returned to indicate the deferral  
  -- ... only valid with EV_DISPATCH2  
  -- returned values  
  -- * Filter specific flags for EVFILT_READ
  -- *
  -- * The default behavior for EVFILT_READ is to make the "read" determination
  -- * relative to the current file descriptor read pointer.
  -- *
  -- * The EV_POLL flag indicates the determination should be made via poll(2)
  -- * semantics. These semantics dictate always returning true for regular files,
  -- * regardless of the amount of unread data in the file.
  -- *
  -- * On input, EV_OOBAND specifies that filter should actively return in the
  -- * presence of OOB on the descriptor. It implies that filter will return
  -- * if there is OOB data available to read OR when any other condition
  -- * for the read are met (for example number of bytes regular data becomes >=
  -- * low-watermark).
  -- * If EV_OOBAND is not set on input, it implies that the filter should not actively
  -- * return for out of band data on the descriptor. The filter will then only return
  -- * when some other condition for read is met (ex: when number of regular data bytes
  -- * >=low-watermark OR when socket can't receive more data (SS_CANTRCVMORE)).
  -- *
  -- * On output, EV_OOBAND indicates the presence of OOB data on the descriptor.
  -- * If it was not specified as an input parameter, then the data count is the
  -- * number of bytes before the current OOB marker, else data count is the number
  -- * of bytes beyond OOB marker.
  --  

  -- * data/hint fflags for EVFILT_USER, shared with userspace
  --  

  -- * On input, NOTE_TRIGGER causes the event to be triggered for output.
  --  

  -- * On input, the top two bits of fflags specifies how the lower twenty four
  -- * bits should be applied to the stored value of fflags.
  -- *
  -- * On output, the top two bits will always be set to NOTE_FFNOP and the
  -- * remaining twenty four bits will contain the stored fflags value.
  --  

  -- * data/hint fflags for EVFILT_{READ|WRITE}, shared with userspace
  -- *
  -- * The default behavior for EVFILT_READ is to make the determination
  -- * realtive to the current file descriptor read pointer.
  --  

  -- data/hint flags for EVFILT_EXCEPT, shared with userspace  
  -- * data/hint fflags for EVFILT_VNODE, shared with userspace
  --  

  -- * data/hint fflags for EVFILT_PROC, shared with userspace
  -- *
  -- * Please note that EVFILT_PROC and EVFILT_SIGNAL share the same knote list
  -- * that hangs off the proc structure. They also both play games with the hint
  -- * passed to KNOTE(). If NOTE_SIGNAL is passed as a hint, then the lower bits
  -- * of the hint contain the signal. IF NOTE_FORK is passed, then the lower bits
  -- * contain the PID of the child (but the pid does not get passed through in
  -- * the actual kevent).
  --  

  -- * If NOTE_EXITSTATUS is present, provide additional info about exiting process.
  --  

  -- * If NOTE_EXIT_DETAIL is present, these bits indicate specific reasons for exiting.
  --  

  -- * data/hint fflags for EVFILT_VM, shared with userspace.
  --  

  -- * data/hint fflags for EVFILT_TIMER, shared with userspace.
  -- * The default is a (repeating) interval timer with the data
  -- * specifying the timeout interval in milliseconds.
  -- *
  -- * All timeouts are implicitly EV_CLEAR events.
  --  

  -- ... implicit EV_ONESHOT, timeout uses the gettimeofday epoch  
  -- * NOTE_MACH_CONTINUOUS_TIME:
  -- * with NOTE_ABSOLUTE: causes the timer to continue to tick across sleep,
  -- *      still uses gettimeofday epoch
  -- * with NOTE_MACHTIME and NOTE_ABSOLUTE: uses mach continuous time epoch
  -- * without NOTE_ABSOLUTE (interval timer mode): continues to tick across sleep
  --  

  -- timeout uses the mach absolute time epoch  
  -- * data/hint fflags for EVFILT_MACHPORT, shared with userspace.
  -- *
  -- * Only portsets are supported at this time.
  -- *
  -- * The fflags field can optionally contain the MACH_RCV_MSG, MACH_RCV_LARGE,
  -- * and related trailer receive options as defined in <mach/message.h>.
  -- * The presence of these flags directs the kevent64() call to attempt to receive
  -- * the message during kevent delivery, rather than just indicate that a message exists.
  -- * On setup, The ext[0] field contains the receive buffer pointer and ext[1] contains
  -- * the receive buffer length.  Upon event delivery, the actual received message size
  -- * is returned in ext[1].  As with mach_msg(), the buffer must be large enough to
  -- * receive the message and the requested (or default) message trailers.  In addition,
  -- * the fflags field contains the return code normally returned by mach_msg().
  -- *
  -- * If MACH_RCV_MSG is specified, and the ext[1] field specifies a zero length, the
  -- * system call argument specifying an ouput area (kevent_qos) will be consulted. If
  -- * the system call specified an output data area, the user-space address
  -- * of the received message is carved from that provided output data area (if enough
  -- * space remains there). The address and length of each received message is
  -- * returned in the ext[0] and ext[1] fields (respectively) of the corresponding kevent.
  -- *
  -- * IF_MACH_RCV_VOUCHER_CONTENT is specified, the contents of the message voucher is
  -- * extracted (as specified in the xflags field) and stored in ext[2] up to ext[3]
  -- * length.  If the input length is zero, and the system call provided a data area,
  -- * the space for the voucher content is carved from the provided space and its
  -- * address and length is returned in ext[2] and ext[3] respectively.
  -- *
  -- * If no message receipt options were provided in the fflags field on setup, no
  -- * message is received by this call. Instead, on output, the data field simply
  -- * contains the name of the actual port detected with a message waiting.
  --  

  -- * DEPRECATED!!!!!!!!!
  -- * NOTE_TRACK, NOTE_TRACKERR, and NOTE_CHILD are no longer supported as of 10.5
  --  

  -- additional flags for EVFILT_PROC  
  -- Temporay solution for BootX to use inode.h till kqueue moves to vfs layer  
   type knote is null record;   -- incomplete struct

   type klist is record
      slh_first : access knote;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:371
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:371

   type timespec is null record;   -- incomplete struct

   function kqueue return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:379
   with Import => True, 
        Convention => C, 
        External_Name => "kqueue";

   function kevent_func
     (kq : int;
      changelist : access constant kevent;
      nchanges : int;
      eventlist : access kevent;
      nevents : int;
      timeout : access constant timespec) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:380
   with Import => True, 
        Convention => C, 
        External_Name => "kevent";

   function kevent64
     (kq : int;
      changelist : access constant kevent64_s;
      nchanges : int;
      eventlist : access kevent64_s;
      nevents : int;
      flags : unsigned;
      timeout : access constant timespec) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/event.h:384
   with Import => True, 
        Convention => C, 
        External_Name => "kevent64";

end sys_event_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
