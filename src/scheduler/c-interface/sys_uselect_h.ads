pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
limited with sys_utypes_ufd_def_h;
limited with sys_utypes_utimeval_h;

package sys_uselect_h is

  -- * Copyright (c) 2005, 2007 Apple Inc. All rights reserved.
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

  -- * This is called from sys/select.h and sys/time.h for the common prototype
  -- * of select().  Setting _DARWIN_C_SOURCE or _DARWIN_UNLIMITED_SELECT uses
  -- * the version of select() that does not place a limit on the first argument
  -- * (nfds).  In the UNIX conformance case, values of nfds greater than
  -- * FD_SETSIZE will return an error of EINVAL.
  --  

  -- __DARWIN_EXTSN_C, __DARWIN_1050, __DARWIN_ALIAS_C  
  -- fd_set  
  -- struct timeval  
   function c_select
     (arg1 : int;
      arg2 : access sys_utypes_ufd_def_h.fd_set;
      arg3 : access sys_utypes_ufd_def_h.fd_set;
      arg4 : access sys_utypes_ufd_def_h.fd_set;
      arg5 : access sys_utypes_utimeval_h.timeval) return int  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/_select.h:43
   with Import => True, 
        Convention => C, 
        External_Name => "_select$1050";

end sys_uselect_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
