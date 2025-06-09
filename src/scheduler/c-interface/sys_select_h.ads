pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
limited with sys_utypes_ufd_def_h;
limited with sys_utypes_utimespec_h;
with sys_utypes_usigset_t_h;

package sys_select_h is

  -- * Copyright (c) 2000-2005 Apple Computer, Inc. All rights reserved.
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

  -- * Copyright (c) 1992, 1993
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
  -- *	@(#)select.h	8.2 (Berkeley) 1/4/94
  --  

  -- * [XSI] The <sys/select.h> header shall define the fd_set type as a structure.
  -- * The timespec structure shall be defined as described in <time.h>
  -- * The <sys/select.h> header shall define the timeval structure.
  --  

  -- * The time_t and suseconds_t types shall be defined as described in
  -- * <sys/types.h>
  -- * The sigset_t type shall be defined as described in <signal.h>
  --  

  -- * [XSI] FD_CLR, FD_ISSET, FD_SET, FD_ZERO may be declared as a function, or
  -- *	 defined as a macro, or both
  -- * [XSI] FD_SETSIZE shall be defined as a macro
  --  

  -- * Select uses bit masks of file descriptors in longs.  These macros
  -- * manipulate such bit fields (the filesystem macros use chars).  The
  -- * extra protection here is to permit application redefinition above
  -- * the default size.
  --  

   function pselect
     (arg1 : int;
      arg2 : access sys_utypes_ufd_def_h.fd_set;
      arg3 : access sys_utypes_ufd_def_h.fd_set;
      arg4 : access sys_utypes_ufd_def_h.fd_set;
      arg5 : access constant sys_utypes_utimespec_h.timespec;
      arg6 : access sys_utypes_usigset_t_h.sigset_t) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/select.h:114
   with Import => True, 
        Convention => C, 
        External_Name => "_pselect$1050";

  -- select() prototype  
end sys_select_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
