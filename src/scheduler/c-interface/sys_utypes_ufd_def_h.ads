pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with i386_utypes_h;

package sys_utypes_ufd_def_h is

  -- * Copyright (c) 2003-2012 Apple Inc. All rights reserved.
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

  -- __int32_t and uintptr_t  
  -- * Select uses bit masks of file descriptors in longs.  These macros
  -- * manipulate such bit fields (the filesystem macros use chars).  The
  -- * extra protection here is to permit application redefinition above
  -- * the default size.
  --  

   type anon_array1163 is array (0 .. 31) of aliased i386_utypes_h.uu_int32_t;
   type fd_set is record
      fds_bits : aliased anon_array1163;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/_types/_fd_def.h:51
   end record
   with Convention => C_Pass_By_Copy;  -- /nix/store/ydnlq230f9gl0sr5ha0jgza0zfhbl1pa-apple-sdk-11.3/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/_types/_fd_def.h:50

   --  skipped func __darwin_check_fd_set_overflow

   --  skipped func __darwin_check_fd_set

  -- This inline avoids argument side-effect issues with FD_ISSET()  
   --  skipped func __darwin_fd_isset

   --  skipped func __darwin_fd_set

   --  skipped func __darwin_fd_clr

  -- * Use the built-in bzero function instead of the library version so that
  -- * we do not pollute the namespace or introduce prototype warnings.
  --  

end sys_utypes_ufd_def_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
