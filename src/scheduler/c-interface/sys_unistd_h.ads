pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with System;
with sys_utypes_usize_t_h;
with utypes_uuint64_t_h;
with Interfaces.C.Strings;
with utypes_uuint32_t_h;
with sys_utypes_uuid_t_h;
with sys_utypes_ugid_t_h;
with sys_utypes_ussize_t_h;

package sys_unistd_h is

   F_OK : constant := 0;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:89
   X_OK : constant := (2**0);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:90
   W_OK : constant := (2**1);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:91
   R_OK : constant := (2**2);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:92
   --  unsupported macro: L_SET SEEK_SET
   --  unsupported macro: L_INCR SEEK_CUR
   --  unsupported macro: L_XTND SEEK_END

   ACCESSX_MAX_DESCRIPTORS : constant := 100;  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:137
   ACCESSX_MAX_TABLESIZE : constant := (16 * 1024);  --  /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:138

  -- * Copyright (c) 2000-2013 Apple Inc. All rights reserved.
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

  -- Copyright (c) 1995 NeXT Computer, Inc. All Rights Reserved  
  -- * Copyright (c) 1989, 1993
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
  -- *	@(#)unistd.h	8.2 (Berkeley) 1/7/94
  --  

  -- * Although we have saved user/group IDs, we do not use them in setuid
  -- * as described in POSIX 1003.1, because the feature does not work for
  -- * root.  We use the saved IDs in seteuid/setegid, which are not currently
  -- * part of the POSIX 1003.1 specification.
  --  

  -- execution-time symbolic constants  
  -- may disable terminal special characters  
  -- access function  
  -- * Extended access functions.
  -- * Note that we depend on these matching the definitions in sys/kauth.h,
  -- * but with the bits shifted left by 8.
  --  

  -- whence values for lseek(2)  
  -- whence values for lseek(2); renamed by POSIX 1003.1  
   type anon_array1263 is array (0 .. 1) of aliased int;
   type accessx_descriptor is record
      ad_name_offset : aliased unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:133
      ad_flags : aliased int;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:134
      ad_pad : aliased anon_array1263;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:135
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:132

  -- configurable pathname variables  
  -- configurable system strings  
   function getattrlistbulk
     (arg1 : int;
      arg2 : System.Address;
      arg3 : System.Address;
      arg4 : sys_utypes_usize_t_h.size_t;
      arg5 : utypes_uuint64_t_h.uint64_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:187
   with Import => True, 
        Convention => C, 
        External_Name => "getattrlistbulk";

   function getattrlistat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : System.Address;
      arg4 : System.Address;
      arg5 : sys_utypes_usize_t_h.size_t;
      arg6 : unsigned_long) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:188
   with Import => True, 
        Convention => C, 
        External_Name => "getattrlistat";

   function setattrlistat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : System.Address;
      arg4 : System.Address;
      arg5 : sys_utypes_usize_t_h.size_t;
      arg6 : utypes_uuint32_t_h.uint32_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:189
   with Import => True, 
        Convention => C, 
        External_Name => "setattrlistat";

   function faccessat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : int;
      arg4 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:207
   with Import => True, 
        Convention => C, 
        External_Name => "faccessat";

   function fchownat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : sys_utypes_uuid_t_h.uid_t;
      arg4 : sys_utypes_ugid_t_h.gid_t;
      arg5 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:208
   with Import => True, 
        Convention => C, 
        External_Name => "fchownat";

   function linkat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : int;
      arg4 : Interfaces.C.Strings.chars_ptr;
      arg5 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:209
   with Import => True, 
        Convention => C, 
        External_Name => "linkat";

   function readlinkat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : Interfaces.C.Strings.chars_ptr;
      arg4 : sys_utypes_usize_t_h.size_t) return sys_utypes_ussize_t_h.ssize_t  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:210
   with Import => True, 
        Convention => C, 
        External_Name => "readlinkat";

   function symlinkat
     (arg1 : Interfaces.C.Strings.chars_ptr;
      arg2 : int;
      arg3 : Interfaces.C.Strings.chars_ptr) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:211
   with Import => True, 
        Convention => C, 
        External_Name => "symlinkat";

   function unlinkat
     (arg1 : int;
      arg2 : Interfaces.C.Strings.chars_ptr;
      arg3 : int) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/unistd.h:212
   with Import => True, 
        Convention => C, 
        External_Name => "unlinkat";

end sys_unistd_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
