/*
**  GSC-18128-1, "Core Flight Executive Version 6.7"
**
**  Copyright (c) 2006-2019 United States Government as represented by
**  the Administrator of the National Aeronautics and Space Administration.
**  All Rights Reserved.
**
**  Licensed under the Apache License, Version 2.0 (the "License");
**  you may not use this file except in compliance with the License.
**  You may obtain a copy of the License at
**
**    http://www.apache.org/licenses/LICENSE-2.0
**
**  Unless required by applicable law or agreed to in writing, software
**  distributed under the License is distributed on an "AS IS" BASIS,
**  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
**  See the License for the specific language governing permissions and
**  limitations under the License.
*/

/**
 * \file target_config.c
 *
 *  Created on: Dec 3, 2013
 *  Created by: joseph.p.hickey@nasa.gov
 *
 * Defines constant configuration structures and pointers that link together
 * the CFE core, PSP, OSAL.  The content of these configuration structures
 * can be used to avoid directly using #include to reference a function
 * implemented in another library, which can greatly simplify include paths
 * and create a more modular build.
 *
 */

#include "target_config.h"
#include "cfe_mission_cfg.h"
#include "cfe_platform_cfg.h"
#include "cfe_es.h"
#include "cfe_time.h"
#include "cfe_es_resetdata_typedef.h"
#include "cfe_version.h"   /* for CFE_VERSION_STRING */
#include "osapi-version.h" /* for OS_VERSION_STRING */

#ifndef CFE_CPU_NAME_VALUE
#define CFE_CPU_NAME_VALUE "unknown"
#endif

#ifndef CFE_CPU_ID_VALUE
#define CFE_CPU_ID_VALUE 0
#endif

#ifndef CFE_SPACECRAFT_ID_VALUE
#define CFE_SPACECRAFT_ID_VALUE 0x42
#endif

#ifndef CFE_DEFAULT_MODULE_EXTENSION
#define CFE_DEFAULT_MODULE_EXTENSION ""
#endif

#ifndef CFE_DEFAULT_CORE_FILENAME
#define CFE_DEFAULT_CORE_FILENAME ""
#endif

/*
 * Many configdata items are instantiated by the
 * build system, where it generates a .c file containing
 * the data, which is then compiled and linked with this file.
 */

extern const char CFE_MISSION_NAME[];   /**< Name of CFE mission */
extern const char CFE_MISSION_CONFIG[]; /**< Configuration name used for build */

/**
 * A list of modules which are statically linked into CFE core.
 *
 * For module names which appear in this list, the code is directly
 * linked into the core executable binary file, and therefore means
 * several things:
 *
 *  - the module code is guaranteed to be present
 *  - functions it provides may be used by CFE core apps
 *  - it cannot be updated/changed without rebuilding CFE core.
 */
extern CFE_ConfigName_t CFE_CORE_MODULE_LIST[];

/**
 * A list of CFS apps which are also statically linked with this binary.
 *
 * These apps can be started without dynamically loading any modules,
 * however the entry point must be separately provided in order to avoid
 * needing any support from the OS dynamic loader subsystem.
 */
extern CFE_ConfigName_t CFE_STATIC_APP_LIST[];

/**
 * A key-value table containing certain environment information from the build system
 * at the time CFE core was built.
 *
 * This contains basic information such as the time of day, build host, and user.
 */
extern CFE_ConfigKeyValue_t CFE_BUILD_ENV_TABLE[];

/**
 * Version control (source code) versions of all modules
 *
 * This list includes all modules known to the build system as determined by the
 * version control system in use (e.g. git).  It is generated by a post-build step
 * to query version control and should change automatically every time code is
 * checked in or out.
 *
 * Notably this includes _all_ modules known to the build system at the time CFE
 * core was built, regardless of whether those modules are configured for runtime
 * (dynamic) or static linkage.
 *
 * For dynamic modules, this means the version info can become outdated if/when
 * a single module is rebuilt/reloaded after the original CFE build.  The keys in
 * this table may be be checked against the CFE_STATIC_MODULE_LIST above to
 * determine if static or dynamic linkage was used.  In the case of dynamic linkage,
 * then this table only represents the version of the module that was present at the
 * time CFE was built, not necessarily the version on the target filesystem.
 */
extern CFE_ConfigKeyValue_t CFE_MODULE_VERSION_TABLE[];

/**
 * A list of PSP modules included in this build of CFE core.
 *
 * These are always statically linked, and this table contains a pointer
 * to its API structure, which in turn contains its entry point.
 */
extern CFE_StaticModuleLoadEntry_t CFE_PSP_MODULE_LIST[];

/**
 * A structure that encapsulates all the CFE static configuration
 */
Target_CfeConfigData GLOBAL_CFE_CONFIGDATA = {
    /*
     * Entry points to CFE code called by the PSP
     */
    .System1HzISR = CFE_TIME_Local1HzISR,
    .SystemMain   = CFE_ES_Main,
    .SystemNotify = CFE_ES_ProcessAsyncEvent,

    /*
     * Default values for various file paths
     */
    .NonvolMountPoint  = CFE_PLATFORM_ES_NONVOL_DISK_MOUNT_STRING,
    .RamdiskMountPoint = CFE_PLATFORM_ES_RAM_DISK_MOUNT_STRING,
    .NonvolStartupFile = CFE_PLATFORM_ES_NONVOL_STARTUP_FILE,

    /*
     * Sizes of other memory segments
     */
    .CdsSize          = CFE_PLATFORM_ES_CDS_SIZE,
    .ResetAreaSize    = sizeof(CFE_ES_ResetData_t),
    .UserReservedSize = CFE_PLATFORM_ES_USER_RESERVED_SIZE,

    .RamDiskSectorSize   = CFE_PLATFORM_ES_RAM_DISK_SECTOR_SIZE,
    .RamDiskTotalSectors = CFE_PLATFORM_ES_RAM_DISK_NUM_SECTORS};

/**
 * Instantiation of global system-wide configuration struct
 * This contains build info plus pointers to the PSP and CFE
 * configuration structures.  Everything will be linked together
 * in the final executable.
 */
Target_ConfigData GLOBAL_CONFIGDATA = {
    .MissionName             = CFE_MISSION_NAME,
    .CfeVersion              = CFE_SRC_VERSION,
    .OsalVersion             = OS_VERSION,
    .Config                  = CFE_MISSION_CONFIG,
    .Default_CpuName         = CFE_CPU_NAME_VALUE,
    .Default_CpuId           = CFE_CPU_ID_VALUE,
    .Default_SpacecraftId    = CFE_SPACECRAFT_ID_VALUE,
    .Default_ModuleExtension = CFE_DEFAULT_MODULE_EXTENSION,
    .Default_CoreFilename    = CFE_DEFAULT_CORE_FILENAME,
    .CfeConfig               = &GLOBAL_CFE_CONFIGDATA,
    .PspModuleList           = CFE_PSP_MODULE_LIST,
    .BuildEnvironment        = CFE_BUILD_ENV_TABLE,
    .ModuleVersionList       = CFE_MODULE_VERSION_TABLE,
    .CoreModuleList          = CFE_CORE_MODULE_LIST,
    .StaticAppList           = CFE_STATIC_APP_LIST,
};
