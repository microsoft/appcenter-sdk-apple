/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#include "MSFakeCXXClass.h"

/*
	This file is purposely empty. Due to a bug in Xcode, a project which links
	to a shared or static library which contains C++ or Objective-C++ code but
	contains no such of its own will attempt to link without the necessary C++
	libraries. The presence of an empty .mm file is sufficient to cause Xcode to
	build with clang++ instead of clang, avoiding the issue.
 */
