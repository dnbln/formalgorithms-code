pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with sys_utypes_uu_int64_t_h;
with sys_utypes_uint64_t_h;
with sys_utypes_uint32_t_h;
with sys_utypes_uu_int32_t_h;
with i386_utypes_h;

package sys_types_h is

   --  arg-macro: function major (x)
   --    return (int32_t)(((u_int32_t)(x) >> 24) and 16#ff#);
   --  arg-macro: function minor (x)
   --    return (int32_t)((x) and 16#ffffff#);
   --  arg-macro: function makedev (x, y)
   --    return (dev_t)(((x) << 24) or (y));
   --  unsupported macro: NBBY __DARWIN_NBBY
   --  unsupported macro: NFDBITS __DARWIN_NFDBITS
   --  arg-macro: procedure howmany (x, y)
   --    __DARWIN_howmany(x, y)
  -- * Copyright (c) 2000-2008 Apple Inc. All rights reserved.
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
  -- * Copyright (c) 1982, 1986, 1991, 1993, 1994
  -- *	The Regents of the University of California.  All rights reserved.
  -- * (c) UNIX System Laboratories, Inc.
  -- * All or some portions of this file are derived from material licensed
  -- * to the University of California by American Telephone and Telegraph
  -- * Co. or Unix System Laboratories, Inc. and are reproduced herein with
  -- * the permission of UNIX System Laboratories, Inc.
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
  -- *	@(#)types.h	8.4 (Berkeley) 1/21/94
  --  

  -- Machine type dependent parameters.  
   subtype u_long is unsigned_long;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:88

  -- Sys V compatibility  
   subtype ushort is unsigned_short;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:91

  -- Sys V compatibility  
   subtype uint is unsigned;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:92

  -- quads  
   subtype u_quad_t is sys_utypes_uu_int64_t_h.u_int64_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:95

   subtype quad_t is sys_utypes_uint64_t_h.int64_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:96

   type qaddr_t is access all quad_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:97

  -- core address  
  -- disk address  
   subtype daddr_t is sys_utypes_uint32_t_h.int32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:101

  -- device number  
  -- fixed point number  
   subtype fixpt_t is sys_utypes_uu_int32_t_h.u_int32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:105

  -- 64bit inode number  
  -- segment size  
   subtype segsz_t is sys_utypes_uint32_t_h.int32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:125

  -- swap offset  
   subtype swblk_t is sys_utypes_uint32_t_h.int32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:126

  -- Major, minor numbers, dev_t's.  
  -- * These lowercase macros tend to match member functions in some C++ code,
  -- * so for C++, we must use inline functions instead.
  --  

  -- * This code is present here in order to maintain historical backward
  -- * compatability, and is intended to be removed at some point in the
  -- * future; please include <sys/select.h> instead.
  --  

   subtype fd_mask is i386_utypes_h.uu_int32_t;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/types.h:189

  -- * Select uses bit masks of file descriptors in longs.  These macros
  -- * manipulate such bit fields (the filesystem macros use chars).  The
  -- * extra protection here is to permit application redefinition above
  -- * the default size.
  --  

  -- statvfs and fstatvfs  
end sys_types_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
