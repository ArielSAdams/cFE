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

/*
 * Test CCSDS Primary header accessors
 */

/*
 * Includes
 */
#include "utassert.h"
#include "ut_support.h"
#include "cfe_msg_api.h"
#include "test_msg_not.h"
#include "test_msg_utils.h"
#include "test_cfe_msg_ccsdspri.h"
#include "cfe_error.h"
#include <string.h>

/*
 * Defines
 */
#define TEST_CCSDSVER_MAX 7      /* Maximum value for CCSDS Version field */
#define TEST_APID_MAX     0x7FF  /* Maximum value for CCSDS ApId field */
#define TEST_SEQUENCE_MAX 0x3FFF /* Maximum value for CCSDS Sequence field */

void Test_MSG_Size(void)
{
    CFE_MSG_Message_t msg;
    CFE_MSG_Size_t    input[] = {TEST_MSG_SIZE_OFFSET, 0x8000, 0xFFFF, 0xFFFF + TEST_MSG_SIZE_OFFSET};
    CFE_MSG_Size_t    actual  = 0;
    int               i;

    UT_Text("Bad parameter tests, Null pointers and invalid (0, min valid - 1, max valid + 1, max)");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetSize(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, 0);
    ASSERT_EQ(CFE_MSG_GetSize(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSize(NULL, input[0]), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(CFE_MSG_SetSize(&msg, 0), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSize(&msg, TEST_MSG_SIZE_OFFSET - 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSize(&msg, 0xFFFF + TEST_MSG_SIZE_OFFSET + 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSize(&msg, 0xFFFFFFFF), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    UT_Text("Set to all F's, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0xFF, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSize(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, 0xFFFF + TEST_MSG_SIZE_OFFSET);
        ASSERT_EQ(CFE_MSG_SetSize(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSize(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == 0xFFFF + TEST_MSG_SIZE_OFFSET)
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), MSG_LENGTH_FLAG);
        }
    }

    UT_Text("Set to all 0, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSize(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, TEST_MSG_SIZE_OFFSET);
        ASSERT_EQ(CFE_MSG_SetSize(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSize(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == TEST_MSG_SIZE_OFFSET)
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_LENGTH_FLAG);
        }
    }
}

void Test_MSG_Type(void)
{
    CFE_MSG_Message_t msg;
    CFE_MSG_Type_t    input[] = {CFE_MSG_Type_Cmd, CFE_MSG_Type_Tlm};
    CFE_MSG_Type_t    actual  = 0;
    int               i;

    UT_Text("Bad parameter tests, Null pointers and invalid (CFE_MSG_Type_Invalid, CFE_MSG_Type_Tlm + 1");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetType(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, 0);
    ASSERT_EQ(CFE_MSG_GetType(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetType(NULL, input[0]), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(CFE_MSG_SetType(&msg, CFE_MSG_Type_Invalid), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetType(&msg, CFE_MSG_Type_Tlm + 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    UT_Text("Set to all F's, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0xFF, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetType(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, CFE_MSG_Type_Cmd);
        ASSERT_EQ(CFE_MSG_SetType(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetType(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == CFE_MSG_Type_Cmd)
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), MSG_TYPE_FLAG);
        }
    }

    UT_Text("Set to all 0, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetType(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, CFE_MSG_Type_Tlm);
        ASSERT_EQ(CFE_MSG_SetType(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetType(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == CFE_MSG_Type_Tlm)
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_TYPE_FLAG);
        }
    }
}

void Test_MSG_HeaderVersion(void)
{
    CFE_MSG_Message_t       msg;
    CFE_MSG_HeaderVersion_t input[] = {0, TEST_CCSDSVER_MAX / 2, TEST_CCSDSVER_MAX};
    CFE_MSG_HeaderVersion_t actual  = TEST_CCSDSVER_MAX;
    int                     i;

    UT_Text("Bad parameter tests, Null pointers and invalid (max valid + 1, max)");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHeaderVersion(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, TEST_CCSDSVER_MAX);
    ASSERT_EQ(CFE_MSG_GetHeaderVersion(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetHeaderVersion(NULL, input[0]), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(CFE_MSG_SetHeaderVersion(&msg, TEST_CCSDSVER_MAX + 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetHeaderVersion(&msg, 0xFFFF), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    UT_Text("Set to all F's, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0xFF, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetHeaderVersion(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, TEST_CCSDSVER_MAX);
        ASSERT_EQ(CFE_MSG_SetHeaderVersion(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetHeaderVersion(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == TEST_CCSDSVER_MAX)
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), MSG_HDRVER_FLAG);
        }
    }

    UT_Text("Set to all 0, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetHeaderVersion(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, 0);
        ASSERT_EQ(CFE_MSG_SetHeaderVersion(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetHeaderVersion(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == 0)
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_HDRVER_FLAG);
        }
    }
}

void Test_MSG_HasSecondaryHeader(void)
{
    CFE_MSG_Message_t msg;
    bool              actual = true;

    UT_Text("Bad parameter tests, Null pointers");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, true);
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetHasSecondaryHeader(NULL, false), CFE_MSG_BAD_ARGUMENT);

    UT_Text("Set to all F's, true and false inputs");
    memset(&msg, 0xFF, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, &actual), CFE_SUCCESS);
    ASSERT_EQ(actual, true);

    ASSERT_EQ(CFE_MSG_SetHasSecondaryHeader(&msg, true), CFE_SUCCESS);
    Test_MSG_PrintMsg(&msg, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, &actual), CFE_SUCCESS);
    ASSERT_EQ(actual, true);
    ASSERT_EQ(Test_MSG_NotF(&msg), 0);

    ASSERT_EQ(CFE_MSG_SetHasSecondaryHeader(&msg, false), CFE_SUCCESS);
    Test_MSG_PrintMsg(&msg, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, &actual), CFE_SUCCESS);
    ASSERT_EQ(actual, false);
    ASSERT_EQ(Test_MSG_NotF(&msg), MSG_HASSEC_FLAG);

    UT_Text("Set to all 0, true and false inputs");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, &actual), CFE_SUCCESS);
    ASSERT_EQ(actual, false);

    ASSERT_EQ(CFE_MSG_SetHasSecondaryHeader(&msg, false), CFE_SUCCESS);
    Test_MSG_PrintMsg(&msg, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, &actual), CFE_SUCCESS);
    ASSERT_EQ(actual, false);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    ASSERT_EQ(CFE_MSG_SetHasSecondaryHeader(&msg, true), CFE_SUCCESS);
    Test_MSG_PrintMsg(&msg, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetHasSecondaryHeader(&msg, &actual), CFE_SUCCESS);
    ASSERT_EQ(actual, true);
    ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_HASSEC_FLAG);
}

void Test_MSG_ApId(void)
{
    CFE_MSG_Message_t msg;
    CFE_MSG_ApId_t    input[] = {0, TEST_APID_MAX / 2, TEST_APID_MAX};
    CFE_MSG_ApId_t    actual  = TEST_APID_MAX;
    int               i;

    UT_Text("Bad parameter tests, Null pointers and invalid (max valid + 1, max)");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetApId(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, TEST_APID_MAX);
    ASSERT_EQ(CFE_MSG_GetApId(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetApId(NULL, input[0]), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(CFE_MSG_SetApId(&msg, TEST_APID_MAX + 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetApId(&msg, 0xFFFF), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    UT_Text("Set to all F's, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0xFF, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetApId(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, TEST_APID_MAX);
        ASSERT_EQ(CFE_MSG_SetApId(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetApId(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == TEST_APID_MAX)
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), MSG_APID_FLAG);
        }
    }

    UT_Text("Set to all 0, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetApId(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, 0);
        ASSERT_EQ(CFE_MSG_SetApId(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetApId(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == 0)
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_APID_FLAG);
        }
    }
}

void Test_MSG_SegmentationFlag(void)
{
    CFE_MSG_Message_t          msg;
    CFE_MSG_SegmentationFlag_t input[] = {CFE_MSG_SegFlag_Continue, CFE_MSG_SegFlag_First, CFE_MSG_SegFlag_Last,
                                          CFE_MSG_SegFlag_Unsegmented};
    CFE_MSG_SegmentationFlag_t actual  = CFE_MSG_SegFlag_Invalid;
    int                        i;

    UT_Text("Bad parameter tests, Null pointers and invalid (*_Invalid, max valid + 1");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetSegmentationFlag(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, CFE_MSG_SegFlag_Invalid);
    ASSERT_EQ(CFE_MSG_GetSegmentationFlag(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSegmentationFlag(NULL, input[0]), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(CFE_MSG_SetSegmentationFlag(&msg, CFE_MSG_SegFlag_Invalid), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSegmentationFlag(&msg, CFE_MSG_SegFlag_Unsegmented + 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    UT_Text("Set to all F's, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0xFF, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSegmentationFlag(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, CFE_MSG_SegFlag_Unsegmented);
        ASSERT_EQ(CFE_MSG_SetSegmentationFlag(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSegmentationFlag(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == CFE_MSG_SegFlag_Unsegmented)
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), MSG_SEGMENT_FLAG);
        }
    }

    UT_Text("Set to all 0, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSegmentationFlag(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, CFE_MSG_SegFlag_Continue);
        ASSERT_EQ(CFE_MSG_SetSegmentationFlag(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSegmentationFlag(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == CFE_MSG_SegFlag_Continue)
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_SEGMENT_FLAG);
        }
    }
}

void Test_MSG_SequenceCount(void)
{
    CFE_MSG_Message_t msg;
    CFE_MSG_ApId_t    input[] = {0, TEST_SEQUENCE_MAX / 2, TEST_SEQUENCE_MAX};
    CFE_MSG_ApId_t    actual  = TEST_SEQUENCE_MAX;
    int               i;

    UT_Text("Bad parameter tests, Null pointers and invalid (max valid + 1, max)");
    memset(&msg, 0, sizeof(msg));
    ASSERT_EQ(CFE_MSG_GetSequenceCount(NULL, &actual), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(actual, TEST_SEQUENCE_MAX);
    ASSERT_EQ(CFE_MSG_GetSequenceCount(&msg, NULL), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSequenceCount(NULL, input[0]), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(CFE_MSG_SetSequenceCount(&msg, TEST_SEQUENCE_MAX + 1), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
    ASSERT_EQ(CFE_MSG_SetSequenceCount(&msg, 0xFFFF), CFE_MSG_BAD_ARGUMENT);
    ASSERT_EQ(Test_MSG_NotZero(&msg), 0);

    UT_Text("Set to all F's, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0xFF, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSequenceCount(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, TEST_SEQUENCE_MAX);
        ASSERT_EQ(CFE_MSG_SetSequenceCount(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSequenceCount(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == TEST_SEQUENCE_MAX)
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotF(&msg), MSG_SEQUENCE_FLAG);
        }
    }

    UT_Text("Set to all 0, various valid inputs");
    for (i = 0; i < sizeof(input) / sizeof(input[0]); i++)
    {
        memset(&msg, 0, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSequenceCount(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, 0);
        ASSERT_EQ(CFE_MSG_SetSequenceCount(&msg, input[i]), CFE_SUCCESS);
        Test_MSG_PrintMsg(&msg, sizeof(msg));
        ASSERT_EQ(CFE_MSG_GetSequenceCount(&msg, &actual), CFE_SUCCESS);
        ASSERT_EQ(actual, input[i]);
        if (input[i] == 0)
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), 0);
        }
        else
        {
            ASSERT_EQ(Test_MSG_NotZero(&msg), MSG_SEQUENCE_FLAG);
        }
    }
}

/*
 * Test MSG ccsdspri
 */
void Test_MSG_CCSDSPri(void)
{
    MSG_UT_ADD_SUBTEST(Test_MSG_Size);
    MSG_UT_ADD_SUBTEST(Test_MSG_Type);
    MSG_UT_ADD_SUBTEST(Test_MSG_HeaderVersion);
    MSG_UT_ADD_SUBTEST(Test_MSG_HasSecondaryHeader);
    MSG_UT_ADD_SUBTEST(Test_MSG_ApId);
    MSG_UT_ADD_SUBTEST(Test_MSG_SegmentationFlag);
    MSG_UT_ADD_SUBTEST(Test_MSG_SequenceCount);
}
