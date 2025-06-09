pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with sys_utypes_uuid_t_h;
with sys_utypes_ugid_t_h;
with System;
with sys_utypes_upid_t_h;
with sys_utypes_usize_t_h;
with sys_utypes_uoff_t_h;
with sys_utypes_ussize_t_h;
with sys_utypes_uuseconds_t_h;
limited with sys_unistd_h;
with sys_utypes_umode_t_h;
with sys_utypes_udev_t_h;

package unistd_h is

   STDIN_FILENO : constant := 0;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:86
   STDOUT_FILENO : constant := 1;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:87
   STDERR_FILENO : constant := 2;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:88

   F_ULOCK : constant := 0;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:527
   F_LOCK : constant := 1;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:528
   F_TLOCK : constant := 2;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:529
   F_TEST : constant := 3;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:530

   SYNC_VOLUME_FULLSYNC : constant := 16#01#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:776
   SYNC_VOLUME_WAIT : constant := 16#02#;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:777

  -- * Copyright (c) 2000, 2002-2006, 2008-2010, 2012 Apple Inc. All rights reserved.
  -- *
  -- * @APPLE_LICENSE_HEADER_START@
  -- * 
  -- * This file contains Original Code and/or Modifications of Original Code
  -- * as defined in and that are subject to the Apple Public Source License
  -- * Version 2.0 (the 'License'). You may not use this file except in
  -- * compliance with the License. Please obtain a copy of the License at
  -- * http://www.opensource.apple.com/apsl/ and read it before using this
  -- * file.
  -- * 
  -- * The Original Code and all software distributed under the License are
  -- * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
  -- * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
  -- * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
  -- * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
  -- * Please see the License for the specific language governing rights and
  -- * limitations under the License.
  -- * 
  -- * @APPLE_LICENSE_HEADER_END@
  --  

  ---
  -- * Copyright (c) 1998-1999 Apple Computer, Inc. All Rights Reserved
  -- * Copyright (c) 1991, 1993, 1994
  -- *	The Regents of the University of California.  All rights reserved.
  -- *
  -- * Redistribution and use in source and binary forms, with or without
  -- * modification, are permitted provided that the following conditions
  -- * are met:
  -- * 1. Redistributions of source code must retain the above copyright
  -- *    notice, this list of conditions and the following disclaimer.
  -- * 2. Redistributions in binary form must reproduce the above copyright
  -- *    notice, this list of conditions and the following disclaimer in the
  -- *    documentation and/or other materials provided with the distribution.
  -- * 3. All advertising materials mentioning features or use of this software
  -- *    must display the following acknowledgement:
  -- *	This product includes software developed by the University of
  -- *	California, Berkeley and its contributors.
  -- * 4. Neither the name of the University nor the names of its contributors
  -- *    may be used to endorse or promote products derived from this software
  -- *    without specific prior written permission.
  -- *
  -- * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
  -- * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  -- * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  -- * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
  -- * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  -- * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  -- * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  -- * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  -- * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  -- * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  -- * SUCH DAMAGE.
  -- *
  -- *	@(#)unistd.h	8.12 (Berkeley) 4/27/95
  -- *
  -- *  Copyright (c)  1998 Apple Compter, Inc.
  -- *  All Rights Reserved
  --  

  -- History:
  --        7/14/99 EKN at Apple fixed getdirentriesattr from getdirentryattr
  --        3/26/98 CHW at Apple added real interface to searchfs call
  --  	3/5/98  CHW at Apple added hfs semantic system calls headers
  -- 

  -- DO NOT REMOVE THIS COMMENT: fixincludes needs to see:
  -- * _GCC_SIZE_T  

  -- Version test macros  
  -- _POSIX_VERSION and _POSIX2_VERSION from sys/unistd.h  
  -- Please keep this list in the same order as the applicable standard  
  -- Removed in Issue 7  
  -- configurable system variables  
  -- Removed in Issue 7  
  -- Removed in Issue 6  
  -- 132-199 available for future use  
  -- Removed in Issue 7  
  -- POSIX.1-1990  
   --  skipped func _exit

   function c_access (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:431
   with Import => True, 
        Convention => C, 
        External_Name => "access";

   function alarm (arg1 : unsigned) return unsigned  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:433
   with Import => True, 
        Convention => C, 
        External_Name => "alarm";

   function chdir (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:434
   with Import => True, 
        Convention => C, 
        External_Name => "chdir";

   function chown
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : sys_utypes_uuid_t_h.uid_t;
      arg3 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:435
   with Import => True, 
        Convention => C, 
        External_Name => "chown";

   function close (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:437
   with Import => True, 
        Convention => C, 
        External_Name => "close";

   function dup (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:439
   with Import => True, 
        Convention => C, 
        External_Name => "dup";

   function dup2 (arg1 : int; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:440
   with Import => True, 
        Convention => C, 
        External_Name => "dup2";

   function execl (uu_path : Interfaces.C.Strings.chars_ptr; uu_arg0 : Interfaces.C.Strings.chars_ptr  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:441
   with Import => True, 
        Convention => C, 
        External_Name => "execl";

   function execle (uu_path : Interfaces.C.Strings.chars_ptr; uu_arg0 : Interfaces.C.Strings.chars_ptr  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:442
   with Import => True, 
        Convention => C, 
        External_Name => "execle";

   function execlp (uu_file : Interfaces.C.Strings.chars_ptr; uu_arg0 : Interfaces.C.Strings.chars_ptr  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:443
   with Import => True, 
        Convention => C, 
        External_Name => "execlp";

   function execv (uu_path : Interfaces.C.Strings.chars_ptr; uu_argv : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:444
   with Import => True, 
        Convention => C, 
        External_Name => "execv";

   function execve
     (uu_file : Interfaces.C.Strings.chars_ptr;
      uu_argv : System.Address;
      uu_envp : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:445
   with Import => True, 
        Convention => C, 
        External_Name => "execve";

   function execvp (uu_file : Interfaces.C.Strings.chars_ptr; uu_argv : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:446
   with Import => True, 
        Convention => C, 
        External_Name => "execvp";

   function fork return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:447
   with Import => True, 
        Convention => C, 
        External_Name => "fork";

   function fpathconf (arg1 : int; arg2 : int) return long  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:448
   with Import => True, 
        Convention => C, 
        External_Name => "fpathconf";

   function getcwd (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : sys_utypes_usize_t_h.size_t) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:449
   with Import => True, 
        Convention => C, 
        External_Name => "getcwd";

   function getegid return sys_utypes_ugid_t_h.gid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:450
   with Import => True, 
        Convention => C, 
        External_Name => "getegid";

   function geteuid return sys_utypes_uuid_t_h.uid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:451
   with Import => True, 
        Convention => C, 
        External_Name => "geteuid";

   function getgid return sys_utypes_ugid_t_h.gid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:452
   with Import => True, 
        Convention => C, 
        External_Name => "getgid";

   function getgroups (arg1 : int; arg2 : access sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:456
   with Import => True, 
        Convention => C, 
        External_Name => "getgroups";

   function getlogin return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:458
   with Import => True, 
        Convention => C, 
        External_Name => "getlogin";

   function getpgrp return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:459
   with Import => True, 
        Convention => C, 
        External_Name => "getpgrp";

   function getpid return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:460
   with Import => True, 
        Convention => C, 
        External_Name => "getpid";

   function getppid return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:461
   with Import => True, 
        Convention => C, 
        External_Name => "getppid";

   function getuid return sys_utypes_uuid_t_h.uid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:462
   with Import => True, 
        Convention => C, 
        External_Name => "getuid";

   function isatty (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:463
   with Import => True, 
        Convention => C, 
        External_Name => "isatty";

   function link (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:464
   with Import => True, 
        Convention => C, 
        External_Name => "link";

   function lseek
     (arg1 : int;
      arg2 : sys_utypes_uoff_t_h.off_t;
      arg3 : int) return sys_utypes_uoff_t_h.off_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:465
   with Import => True, 
        Convention => C, 
        External_Name => "lseek";

   function pathconf (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return long  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:466
   with Import => True, 
        Convention => C, 
        External_Name => "pathconf";

   function pause return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:468
   with Import => True, 
        Convention => C, 
        External_Name => "_pause";

   function pipe (arg1 : access int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:470
   with Import => True, 
        Convention => C, 
        External_Name => "pipe";

   function read
     (arg1 : int;
      arg2 : System.Address;
      arg3 : sys_utypes_usize_t_h.size_t) return sys_utypes_ussize_t_h.ssize_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:472
   with Import => True, 
        Convention => C, 
        External_Name => "read";

   function rmdir (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:474
   with Import => True, 
        Convention => C, 
        External_Name => "rmdir";

   function setgid (arg1 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:475
   with Import => True, 
        Convention => C, 
        External_Name => "setgid";

   function setpgid (arg1 : sys_utypes_upid_t_h.pid_t; arg2 : sys_utypes_upid_t_h.pid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:476
   with Import => True, 
        Convention => C, 
        External_Name => "setpgid";

   function setsid return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:477
   with Import => True, 
        Convention => C, 
        External_Name => "setsid";

   function setuid (arg1 : sys_utypes_uuid_t_h.uid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:478
   with Import => True, 
        Convention => C, 
        External_Name => "setuid";

   function sleep (arg1 : unsigned) return unsigned  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:481
   with Import => True, 
        Convention => C, 
        External_Name => "_sleep";

   function sysconf (arg1 : int) return long  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:483
   with Import => True, 
        Convention => C, 
        External_Name => "sysconf";

   function tcgetpgrp (arg1 : int) return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:484
   with Import => True, 
        Convention => C, 
        External_Name => "tcgetpgrp";

   function tcsetpgrp (arg1 : int; arg2 : sys_utypes_upid_t_h.pid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:485
   with Import => True, 
        Convention => C, 
        External_Name => "tcsetpgrp";

   function ttyname (arg1 : int) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:486
   with Import => True, 
        Convention => C, 
        External_Name => "ttyname";

   function ttyname_r
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : sys_utypes_usize_t_h.size_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:489
   with Import => True, 
        Convention => C, 
        External_Name => "_ttyname_r";

   function unlink (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:494
   with Import => True, 
        Convention => C, 
        External_Name => "unlink";

   function write
     (uu_fd : int;
      uu_buf : System.Address;
      uu_nbyte : sys_utypes_usize_t_h.size_t) return sys_utypes_ussize_t_h.ssize_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:496
   with Import => True, 
        Convention => C, 
        External_Name => "write";

  -- Additional functionality provided by:
  -- * POSIX.2-1992 C Language Binding Option
  --  

   function confstr
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : sys_utypes_usize_t_h.size_t) return sys_utypes_usize_t_h.size_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:507
   with Import => True, 
        Convention => C, 
        External_Name => "_confstr";

   function getopt
     (arg1 : int;
      arg2 : System.Address;
      arg3 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:509
   with Import => True, 
        Convention => C, 
        External_Name => "_getopt";

  -- getopt(3) external variables  
   optarg : Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:511
   with Import => True, 
        Convention => C, 
        External_Name => "optarg";

   optind : aliased int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:512
   with Import => True, 
        Convention => C, 
        External_Name => "optind";

   opterr : aliased int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:512
   with Import => True, 
        Convention => C, 
        External_Name => "opterr";

   optopt : aliased int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:512
   with Import => True, 
        Convention => C, 
        External_Name => "optopt";

  -- Additional functionality provided by:
  -- * POSIX.1c-1995,
  -- * POSIX.1i-1995,
  -- * and the omnibus ISO/IEC 9945-1: 1996
  --  

  -- These F_* are really XSI or Issue 6  
  -- Begin XSI  
  -- Removed in Issue 6  
   function brk (arg1 : System.Address) return System.Address  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:540
   with Import => True, 
        Convention => C, 
        External_Name => "brk";

   function chroot (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:541
   with Import => True, 
        Convention => C, 
        External_Name => "chroot";

   function crypt (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:544
   with Import => True, 
        Convention => C, 
        External_Name => "crypt";

   procedure encrypt (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int)  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:546
   with Import => True, 
        Convention => C, 
        External_Name => "_encrypt";

   function fchdir (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:550
   with Import => True, 
        Convention => C, 
        External_Name => "fchdir";

   function gethostid return long  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:551
   with Import => True, 
        Convention => C, 
        External_Name => "gethostid";

   function getpgid (arg1 : sys_utypes_upid_t_h.pid_t) return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:552
   with Import => True, 
        Convention => C, 
        External_Name => "getpgid";

   function getsid (arg1 : sys_utypes_upid_t_h.pid_t) return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:553
   with Import => True, 
        Convention => C, 
        External_Name => "getsid";

  -- Removed in Issue 6  
   function getdtablesize return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:557
   with Import => True, 
        Convention => C, 
        External_Name => "getdtablesize";

   function getpagesize return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:558
   with Import => True, 
        Convention => C, 
        External_Name => "getpagesize";

   function getpass (arg1 : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:559
   with Import => True, 
        Convention => C, 
        External_Name => "getpass";

  -- Removed in Issue 7  
  -- obsoleted by getcwd()  
   function getwd (arg1 : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:564
   with Import => True, 
        Convention => C, 
        External_Name => "getwd";

   function lchown
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : sys_utypes_uuid_t_h.uid_t;
      arg3 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:567
   with Import => True, 
        Convention => C, 
        External_Name => "_lchown";

   function lockf
     (arg1 : int;
      arg2 : int;
      arg3 : sys_utypes_uoff_t_h.off_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:569
   with Import => True, 
        Convention => C, 
        External_Name => "_lockf";

   function nice (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:571
   with Import => True, 
        Convention => C, 
        External_Name => "_nice";

   function pread
     (uu_fd : int;
      uu_buf : System.Address;
      uu_nbyte : sys_utypes_usize_t_h.size_t;
      uu_offset : sys_utypes_uoff_t_h.off_t) return sys_utypes_ussize_t_h.ssize_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:573
   with Import => True, 
        Convention => C, 
        External_Name => "_pread";

   function pwrite
     (uu_fd : int;
      uu_buf : System.Address;
      uu_nbyte : sys_utypes_usize_t_h.size_t;
      uu_offset : sys_utypes_uoff_t_h.off_t) return sys_utypes_ussize_t_h.ssize_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:575
   with Import => True, 
        Convention => C, 
        External_Name => "_pwrite";

  -- Removed in Issue 6  
  -- Note that Issue 5 changed the argument as intprt_t,
  -- * but we keep it as int for binary compatability.  

   function sbrk (arg1 : int) return System.Address  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:584
   with Import => True, 
        Convention => C, 
        External_Name => "sbrk";

   function setpgrp return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:588
   with Import => True, 
        Convention => C, 
        External_Name => "_setpgrp";

  -- obsoleted by setpgid()  
   function setregid (arg1 : sys_utypes_ugid_t_h.gid_t; arg2 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:593
   with Import => True, 
        Convention => C, 
        External_Name => "_setregid";

   function setreuid (arg1 : sys_utypes_uuid_t_h.uid_t; arg2 : sys_utypes_uuid_t_h.uid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:595
   with Import => True, 
        Convention => C, 
        External_Name => "_setreuid";

   procedure swab
     (arg1 : System.Address;
      arg2 : System.Address;
      arg3 : sys_utypes_ussize_t_h.ssize_t)  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:597
   with Import => True, 
        Convention => C, 
        External_Name => "swab";

   procedure sync  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:598
   with Import => True, 
        Convention => C, 
        External_Name => "sync";

   function truncate (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : sys_utypes_uoff_t_h.off_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:599
   with Import => True, 
        Convention => C, 
        External_Name => "truncate";

   function ualarm (arg1 : sys_utypes_uuseconds_t_h.useconds_t; arg2 : sys_utypes_uuseconds_t_h.useconds_t) return sys_utypes_uuseconds_t_h.useconds_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:600
   with Import => True, 
        Convention => C, 
        External_Name => "ualarm";

   function usleep (arg1 : sys_utypes_uuseconds_t_h.useconds_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:601
   with Import => True, 
        Convention => C, 
        External_Name => "_usleep";

   function vfork return sys_utypes_upid_t_h.pid_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:602
   with Import => True, 
        Convention => C, 
        External_Name => "vfork";

  -- End XSI  
   function fsync (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:605
   with Import => True, 
        Convention => C, 
        External_Name => "_fsync";

   function ftruncate (arg1 : int; arg2 : sys_utypes_uoff_t_h.off_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:607
   with Import => True, 
        Convention => C, 
        External_Name => "ftruncate";

   function getlogin_r (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : sys_utypes_usize_t_h.size_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:608
   with Import => True, 
        Convention => C, 
        External_Name => "getlogin_r";

  -- Additional functionality provided by:
  -- * POSIX.1-2001
  -- * ISO C99
  --  

   function fchown
     (arg1 : int;
      arg2 : sys_utypes_uuid_t_h.uid_t;
      arg3 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:621
   with Import => True, 
        Convention => C, 
        External_Name => "fchown";

   function gethostname (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : sys_utypes_usize_t_h.size_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:622
   with Import => True, 
        Convention => C, 
        External_Name => "gethostname";

   function readlink
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : sys_utypes_usize_t_h.size_t) return sys_utypes_ussize_t_h.ssize_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:623
   with Import => True, 
        Convention => C, 
        External_Name => "readlink";

   function setegid (arg1 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:624
   with Import => True, 
        Convention => C, 
        External_Name => "setegid";

   function seteuid (arg1 : sys_utypes_uuid_t_h.uid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:625
   with Import => True, 
        Convention => C, 
        External_Name => "seteuid";

   function symlink (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:626
   with Import => True, 
        Convention => C, 
        External_Name => "symlink";

  -- Darwin extensions  
   --  skipped func _Exit

   function accessx_np
     (arg1 : access constant sys_unistd_h.accessx_descriptor;
      arg2 : sys_utypes_usize_t_h.size_t;
      arg3 : access int;
      arg4 : sys_utypes_uuid_t_h.uid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:643
   with Import => True, 
        Convention => C, 
        External_Name => "accessx_np";

   function acct (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:644
   with Import => True, 
        Convention => C, 
        External_Name => "acct";

   function add_profil
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : sys_utypes_usize_t_h.size_t;
      arg3 : unsigned_long;
      arg4 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:645
   with Import => True, 
        Convention => C, 
        External_Name => "add_profil";

   procedure endusershell  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:646
   with Import => True, 
        Convention => C, 
        External_Name => "endusershell";

   function execvP
     (uu_file : Interfaces.C.Strings.chars_ptr;
      uu_searchpath : Interfaces.C.Strings.chars_ptr;
      uu_argv : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:647
   with Import => True, 
        Convention => C, 
        External_Name => "execvP";

   function fflagstostr (arg1 : unsigned_long) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:648
   with Import => True, 
        Convention => C, 
        External_Name => "fflagstostr";

   function getdomainname (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:649
   with Import => True, 
        Convention => C, 
        External_Name => "getdomainname";

   function getgrouplist
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : int;
      arg3 : access int;
      arg4 : access int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:650
   with Import => True, 
        Convention => C, 
        External_Name => "getgrouplist";

   function getmode (arg1 : System.Address; arg2 : sys_utypes_umode_t_h.mode_t) return sys_utypes_umode_t_h.mode_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:660
   with Import => True, 
        Convention => C, 
        External_Name => "getmode";

   function getpeereid
     (arg1 : int;
      arg2 : access sys_utypes_uuid_t_h.uid_t;
      arg3 : access sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:661
   with Import => True, 
        Convention => C, 
        External_Name => "getpeereid";

   function getsgroups_np (arg1 : access int; arg2 : access unsigned_char) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:662
   with Import => True, 
        Convention => C, 
        External_Name => "getsgroups_np";

   function getusershell return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:663
   with Import => True, 
        Convention => C, 
        External_Name => "getusershell";

   function getwgroups_np (arg1 : access int; arg2 : access unsigned_char) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:664
   with Import => True, 
        Convention => C, 
        External_Name => "getwgroups_np";

   function initgroups (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:665
   with Import => True, 
        Convention => C, 
        External_Name => "initgroups";

   function issetugid return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:666
   with Import => True, 
        Convention => C, 
        External_Name => "issetugid";

   function mkdtemp (arg1 : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:667
   with Import => True, 
        Convention => C, 
        External_Name => "mkdtemp";

   function mknod
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : sys_utypes_umode_t_h.mode_t;
      arg3 : sys_utypes_udev_t_h.dev_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:668
   with Import => True, 
        Convention => C, 
        External_Name => "mknod";

  -- returns errno  
   function mkpath_np (path : Interfaces.C.Strings.chars_ptr; omode : sys_utypes_umode_t_h.mode_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:669
   with Import => True, 
        Convention => C, 
        External_Name => "mkpath_np";

  -- returns errno  
   function mkpathat_np
     (dfd : int;
      path : Interfaces.C.Strings.chars_ptr;
      omode : sys_utypes_umode_t_h.mode_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:670
   with Import => True, 
        Convention => C, 
        External_Name => "mkpathat_np";

   function mkstemp (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:673
   with Import => True, 
        Convention => C, 
        External_Name => "mkstemp";

   function mkstemps (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:674
   with Import => True, 
        Convention => C, 
        External_Name => "mkstemps";

   function mktemp (arg1 : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:675
   with Import => True, 
        Convention => C, 
        External_Name => "mktemp";

   function mkostemp (path : Interfaces.C.Strings.chars_ptr; oflags : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:676
   with Import => True, 
        Convention => C, 
        External_Name => "mkostemp";

   function mkostemps
     (path : Interfaces.C.Strings.chars_ptr;
      slen : int;
      oflags : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:679
   with Import => True, 
        Convention => C, 
        External_Name => "mkostemps";

  -- Non-portable mkstemp that uses open_dprotected_np  
   function mkstemp_dprotected_np
     (path : Interfaces.C.Strings.chars_ptr;
      dpclass : int;
      dpflags : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:683
   with Import => True, 
        Convention => C, 
        External_Name => "mkstemp_dprotected_np";

   function mkdtempat_np (dfd : int; path : Interfaces.C.Strings.chars_ptr) return Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:686
   with Import => True, 
        Convention => C, 
        External_Name => "mkdtempat_np";

   function mkstempsat_np
     (dfd : int;
      path : Interfaces.C.Strings.chars_ptr;
      slen : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:689
   with Import => True, 
        Convention => C, 
        External_Name => "mkstempsat_np";

   function mkostempsat_np
     (dfd : int;
      path : Interfaces.C.Strings.chars_ptr;
      slen : int;
      oflags : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:692
   with Import => True, 
        Convention => C, 
        External_Name => "mkostempsat_np";

   function nfssvc (arg1 : int; arg2 : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:695
   with Import => True, 
        Convention => C, 
        External_Name => "nfssvc";

   function profil
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : sys_utypes_usize_t_h.size_t;
      arg3 : unsigned_long;
      arg4 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:696
   with Import => True, 
        Convention => C, 
        External_Name => "profil";

   function pthread_setugid_np (arg1 : sys_utypes_uuid_t_h.uid_t; arg2 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:699
   with Import => True, 
        Convention => C, 
        External_Name => "pthread_setugid_np";

   function pthread_getugid_np (arg1 : access sys_utypes_uuid_t_h.uid_t; arg2 : access sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:700
   with Import => True, 
        Convention => C, 
        External_Name => "pthread_getugid_np";

   function reboot (arg1 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:702
   with Import => True, 
        Convention => C, 
        External_Name => "reboot";

   function revoke (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:703
   with Import => True, 
        Convention => C, 
        External_Name => "revoke";

   function rcmd
     (arg1 : System.Address;
      arg2 : int;
      arg3 : Interfaces.C.Strings.chars_ptr;
      arg4 : Interfaces.C.Strings.chars_ptr;
      arg5 : Interfaces.C.Strings.chars_ptr;
      arg6 : access int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:705
   with Import => True, 
        Convention => C, 
        External_Name => "rcmd";

   function rcmd_af
     (arg1 : System.Address;
      arg2 : int;
      arg3 : Interfaces.C.Strings.chars_ptr;
      arg4 : Interfaces.C.Strings.chars_ptr;
      arg5 : Interfaces.C.Strings.chars_ptr;
      arg6 : access int;
      arg7 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:706
   with Import => True, 
        Convention => C, 
        External_Name => "rcmd_af";

   function rresvport (arg1 : access int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:708
   with Import => True, 
        Convention => C, 
        External_Name => "rresvport";

   function rresvport_af (arg1 : access int; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:709
   with Import => True, 
        Convention => C, 
        External_Name => "rresvport_af";

   function iruserok
     (arg1 : unsigned_long;
      arg2 : int;
      arg3 : Interfaces.C.Strings.chars_ptr;
      arg4 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:710
   with Import => True, 
        Convention => C, 
        External_Name => "iruserok";

   function iruserok_sa
     (arg1 : System.Address;
      arg2 : int;
      arg3 : int;
      arg4 : Interfaces.C.Strings.chars_ptr;
      arg5 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:711
   with Import => True, 
        Convention => C, 
        External_Name => "iruserok_sa";

   function ruserok
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : int;
      arg3 : Interfaces.C.Strings.chars_ptr;
      arg4 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:712
   with Import => True, 
        Convention => C, 
        External_Name => "ruserok";

   function setdomainname (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:714
   with Import => True, 
        Convention => C, 
        External_Name => "setdomainname";

   function setgroups (arg1 : int; arg2 : access sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:715
   with Import => True, 
        Convention => C, 
        External_Name => "setgroups";

   procedure sethostid (arg1 : long)  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:716
   with Import => True, 
        Convention => C, 
        External_Name => "sethostid";

   function sethostname (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:717
   with Import => True, 
        Convention => C, 
        External_Name => "sethostname";

   procedure setkey (arg1 : Interfaces.C.Strings.chars_ptr)  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:719
   with Import => True, 
        Convention => C, 
        External_Name => "_setkey";

   function setlogin (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:723
   with Import => True, 
        Convention => C, 
        External_Name => "setlogin";

   function setmode (arg1 : Interfaces.C.Strings.chars_ptr) return System.Address  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:724
   with Import => True, 
        Convention => C, 
        External_Name => "_setmode";

   function setrgid (arg1 : sys_utypes_ugid_t_h.gid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:725
   with Import => True, 
        Convention => C, 
        External_Name => "setrgid";

   function setruid (arg1 : sys_utypes_uuid_t_h.uid_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:726
   with Import => True, 
        Convention => C, 
        External_Name => "setruid";

   function setsgroups_np (arg1 : int; arg2 : access unsigned_char) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:727
   with Import => True, 
        Convention => C, 
        External_Name => "setsgroups_np";

   procedure setusershell  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:728
   with Import => True, 
        Convention => C, 
        External_Name => "setusershell";

   function setwgroups_np (arg1 : int; arg2 : access unsigned_char) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:729
   with Import => True, 
        Convention => C, 
        External_Name => "setwgroups_np";

   function strtofflags
     (arg1 : System.Address;
      arg2 : access unsigned_long;
      arg3 : access unsigned_long) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:730
   with Import => True, 
        Convention => C, 
        External_Name => "strtofflags";

   function swapon (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:731
   with Import => True, 
        Convention => C, 
        External_Name => "swapon";

   function ttyslot return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:732
   with Import => True, 
        Convention => C, 
        External_Name => "ttyslot";

   function undelete (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:733
   with Import => True, 
        Convention => C, 
        External_Name => "undelete";

   function unwhiteout (arg1 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:734
   with Import => True, 
        Convention => C, 
        External_Name => "unwhiteout";

   function valloc (arg1 : sys_utypes_usize_t_h.size_t) return System.Address  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:735
   with Import => True, 
        Convention => C, 
        External_Name => "valloc";

   function syscall (arg1 : int  -- , ...
      ) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:742
   with Import => True, 
        Convention => C, 
        External_Name => "syscall";

  -- getsubopt(3) external variable  
   suboptarg : Interfaces.C.Strings.chars_ptr  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:744
   with Import => True, 
        Convention => C, 
        External_Name => "suboptarg";

   function getsubopt
     (arg1 : System.Address;
      arg2 : System.Address;
      arg3 : System.Address) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:745
   with Import => True, 
        Convention => C, 
        External_Name => "getsubopt";

  --  HFS & HFS Plus semantics system calls go here  
   function fgetattrlist
     (arg1 : int;
      arg2 : System.Address;
      arg3 : System.Address;
      arg4 : sys_utypes_usize_t_h.size_t;
      arg5 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:749
   with Import => True, 
        Convention => C, 
        External_Name => "fgetattrlist";

   function fsetattrlist
     (arg1 : int;
      arg2 : System.Address;
      arg3 : System.Address;
      arg4 : sys_utypes_usize_t_h.size_t;
      arg5 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:750
   with Import => True, 
        Convention => C, 
        External_Name => "fsetattrlist";

   function getattrlist
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : System.Address;
      arg3 : System.Address;
      arg4 : sys_utypes_usize_t_h.size_t;
      arg5 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:751
   with Import => True, 
        Convention => C, 
        External_Name => "_getattrlist";

   function setattrlist
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : System.Address;
      arg3 : System.Address;
      arg4 : sys_utypes_usize_t_h.size_t;
      arg5 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:752
   with Import => True, 
        Convention => C, 
        External_Name => "_setattrlist";

   function exchangedata
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:753
   with Import => True, 
        Convention => C, 
        External_Name => "exchangedata";

   function getdirentriesattr
     (arg1 : int;
      arg2 : System.Address;
      arg3 : System.Address;
      arg4 : sys_utypes_usize_t_h.size_t;
      arg5 : access unsigned;
      arg6 : access unsigned;
      arg7 : access unsigned;
      arg8 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:754
   with Import => True, 
        Convention => C, 
        External_Name => "getdirentriesattr";

   type fssearchblock is null record;   -- incomplete struct

   type searchstate is null record;   -- incomplete struct

   function searchfs
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : access fssearchblock;
      arg3 : access unsigned_long;
      arg4 : unsigned;
      arg5 : unsigned;
      arg6 : access searchstate) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:772
   with Import => True, 
        Convention => C, 
        External_Name => "searchfs";

   function fsctl
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : unsigned_long;
      arg3 : System.Address;
      arg4 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:773
   with Import => True, 
        Convention => C, 
        External_Name => "fsctl";

   function ffsctl
     (arg1 : int;
      arg2 : unsigned_long;
      arg3 : System.Address;
      arg4 : unsigned) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:774
   with Import => True, 
        Convention => C, 
        External_Name => "ffsctl";

   function fsync_volume_np (arg1 : int; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:779
   with Import => True, 
        Convention => C, 
        External_Name => "fsync_volume_np";

   function sync_volume_np (arg1 : Interfaces.C.Strings.chars_ptr; arg2 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:780
   with Import => True, 
        Convention => C, 
        External_Name => "sync_volume_np";

   optreset : aliased int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/unistd.h:782
   with Import => True, 
        Convention => C, 
        External_Name => "optreset";

end unistd_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
