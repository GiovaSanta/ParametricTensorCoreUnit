#include <stdio.h>

#include <stdint.h>

#include "functions.h"
#include "KTCU_hmma.h"

#define N_ROW_1 16

#define N_COL_1 16

#define N_COL_2 16

typedef uint32_t posit32_t;

posit32_t A[N_ROW_1][N_COL_1] = { //A is stored in row major layout

    {0x60621FBD, 0xB05A5662, 0x61BCD12C, 0x5CA1AD84, 0x9D81C01B, 0x639C262F, 0x602DA0D3, 0x6093B82A, 0x9E0CC0E1, 0xB34C7E2A, 0xA7BB27A3, 0x62D40786, 0x5935160C, 0x612A0815, 0xB18397CB, 0x9FA2C512},
    {0x4DF944C3, 0x9D05653E, 0x613DFA2F, 0x586D3084, 0x6021209C, 0xA6B08DB0, 0x6387FAA7, 0x624A395F, 0x60744241, 0x9F1D3D7A, 0xB77B0717, 0x9CB36B94, 0x9E77F842, 0x5BB712F5, 0x5FAA2EE4, 0x637AEB7C},
    {0xA4DA529A, 0xA7B59CA0, 0xB8699E8A, 0x9F08131F, 0x9E142893, 0xBB8F9899, 0x9FA16BB3, 0x5ADE3B84, 0xAFF49815, 0x6152A65F, 0x5CD124B8, 0xA3FDD0A7, 0x6150EFA7, 0x60E05097, 0xA998E43B, 0xA273F7B8},
    {0x5BAE019F, 0x9E3C6D1A, 0x9F32D2F1, 0x9C1E27E6, 0x60973E04, 0x5A8CEA9B, 0x5D216DF8, 0x607DDDB9, 0xB57B8118, 0x50CC82F2, 0x9E3C9BC7, 0x9DD51D7D, 0x5AC71D37, 0xB933859D, 0x5059A820, 0x603D6F71},
    {0x589F3997, 0x4DB7612E, 0x4F283353, 0xA373EB1D, 0x9C7E3AD7, 0xAFE65AFC, 0x9F6EF056, 0xAC4AAAA6, 0x61A789FB, 0x9FBE3755, 0x9CEECEDB, 0xA2023195, 0xA2CA3D79, 0x5A5CD716, 0x4E99A8BD, 0x608AD8D9},
    {0x5A841CF0, 0xAC047C14, 0x61063A3D, 0x9EABEBCC, 0x9C5D0756, 0x9D70D607, 0x5E3B22B7, 0xB63D960F, 0x9E9491B8, 0x208F0D5D, 0x9E6FDED1, 0x5C908356, 0xB2374C34, 0xA8C54DB5, 0xA34BF95D, 0x58568CCD},
    {0xA727F014, 0x9D67039A, 0x9DE35A28, 0x6363EECE, 0x62898BE8, 0x5CC8006E, 0xA1040371, 0x6381BF17, 0x6075C382, 0x5DE18763, 0xB3095AFC, 0xA16C67DF, 0x9D8AD140, 0x62710F36, 0xB4ADC143, 0x9F3CE15E},
    {0xA394CB18, 0x5223DDE9, 0x9ED40FB3, 0x61B4B12E, 0x6022E560, 0x5E0BAE5B, 0xAF4ED321, 0x5825D3FB, 0x52C3B8E5, 0x59971633, 0x9D59E24A, 0xAD392D4D, 0x9CAA73A0, 0xCBB17569, 0xA51C7234, 0x9E4FF899},
    {0x9DA789DF, 0x5337EFF6, 0x9EBABFB1, 0x62CD4AC1, 0x52603620, 0xA6331D69, 0x53A31E6B, 0x9C5D6798, 0x63564230, 0xBEF079E1, 0x60861560, 0x9D52DCB1, 0xC2568FBD, 0xC67BE4F3, 0x63015650, 0x512E6284},
    {0xBA6D33E9, 0xA1162117, 0xA5386D2C, 0x429592B9, 0xB05C8060, 0x9C5885E9, 0x61387DE1, 0x6256ACAD, 0x9E3E75D4, 0x4DD5500D, 0x9DBCB9EB, 0x5B05FB50, 0xA1FFBBFC, 0x5A33FAFF, 0x5E87146B, 0x604C6150},
    {0x9DB94E92, 0x62A7FC09, 0x9FAEF4DE, 0x9C993DE9, 0x4E0ACFBA, 0xA7BD30D2, 0x6146D19C, 0x60EE9918, 0xA44C00ED, 0x633F1370, 0xA29E65DA, 0x3F6B22D6, 0xA061BB67, 0x62FA08D3, 0x9EA23BCF, 0x9CB7F433},
    {0xAFB142AE, 0x63E0C533, 0x62444F62, 0x5FE9319C, 0x6240AFA0, 0x624B8EB4, 0x41A7CD92, 0xA4382E7C, 0x605A29B5, 0x5A58A87C, 0xA7EA021B, 0x9D82EF7B, 0x5FCB66A7, 0xA0CC2731, 0x62FD2FC9, 0x9FDB03F6},
    {0x9DF6D106, 0x614C3CCD, 0x9E73DA41, 0x9EDE4872, 0x54B89348, 0x61FE34C4, 0x9F2498AD, 0xA3DC57D3, 0x6070400E, 0x638C99DE, 0x1E126150, 0x9E4D6778, 0x9C391542, 0x9FACABCD, 0x9E1BF19D, 0x5B5EC27C},
    {0x9DF306A4, 0x34F6B50A, 0x5C6ECBB6, 0x52620770, 0x9F3247F4, 0x60DDB1AE, 0x5DC93AFC, 0x5F4B8390, 0x9E18D003, 0x9DFAE545, 0x62D74BD4, 0xAAE3D79E, 0xA342BE4D, 0xC44F6041, 0x5A6C5E05, 0x634A3B9D},
    {0xA255228E, 0x62CC03EC, 0x9C65D311, 0x4E21757B, 0x58930C59, 0x9DB1C17A, 0x9E3ED4BC, 0xADA589BB, 0x6375AF98, 0x544B1F55, 0x62EDA9C2, 0x60DEA98D, 0xB7A65215, 0x608E641E, 0x9C490F39, 0x9DBF0DC7},
    {0x614556F0, 0x60BFC346, 0x9FB8E580, 0x47C10823, 0x5591ED29, 0x61E2423E, 0x55329D86, 0xACCF252B, 0xA7F2A1A1, 0xAE834DE0, 0x59B93CE9, 0x61E13DDB, 0xB4329608, 0x9FF7269E, 0x9FC95E79, 0x5FBEB2AE}

};


posit32_t B_T[N_COL_2][N_COL_1] = { //B is stored in column major layout in memory (so this below is B transpose)

    {   0x6110AA68, 0x9CDAA703, 0x442958B4, 0x61B89D92, 0x62A95C8A, 0x9D85831F, 0x50504D38, 0xA55A522F,0xA82C8C17, 0xA352C744, 0x9E49D14E, 0x5CAE02CC, 0x9CDF3BB9, 0x51FC77D7, 0xAC530143, 0xAF38B620 },
    {    0x9DAF3811, 0x53AA99BF, 0x9DA072B8, 0xB67A04EC, 0xBE39E444, 0x5E721FF6, 0x51456731, 0x625FB59A, 0x63C93E29, 0x62B1F021, 0x606DA438, 0x61685DF2, 0x56E3365B, 0x5CC9210B, 0x9F7B680D, 0x581096A7 },
    {   0x9D10A005, 0x5B90D3AA, 0x6155D8A3, 0xA94A9CD4, 0xA503DEB7, 0x9D5A1590, 0xB74ACD90, 0x603354E9, 0x5DEFC8A1, 0x60802E2D, 0x9F2BD832, 0x9CA475B0, 0x9CAD77C6, 0x598D0938, 0x534D9E80, 0xA7150280},
    {   0x541666FD, 0xAA627B99, 0x9CD4D5F7, 0x58EE9AC9, 0x4912411F, 0x62F99C09, 0x4396645F, 0xA15071C9, 0x633817E4, 0x9DC4F85B, 0x6291F964, 0x9F3A7FE1,0x622575F9, 0x630CACB9, 0xA44A65F6, 0x3D0B843C },
    {    0x9E56B9C1, 0xA459F754, 0x62CC26FD, 0xA10DBC29, 0x6193B42A, 0x9E32D2A8, 0x603907BC, 0xA74EEC09, 0x9DE549CB, 0x63F3DA9D, 0x5A004FDB, 0x9DFFAFF9, 0x5D69BB0A, 0x9E600190, 0x9C93B37A, 0x5F262F9E },
    {    0x6131D314, 0x31450D40, 0x9D95F7A9, 0x9E3C7DCD, 0x59C3FDB1, 0x635792D0, 0x60C9B4D4, 0xA41FC8DE, 0x619BC934, 0x6211340B, 0x9C941F5A, 0x31478B36, 0x9EC521B4, 0x388D9ECA, 0xAD8E21F5, 0x622EB4CB},
    {   0xA3DC85F7, 0x6200052F, 0x617F4873, 0xBCAC547F, 0x60DEC9F7, 0x60D06BED, 0xC7F70336, 0x9E8593CB, 0x58C5D18A, 0xA22B8E4C, 0x9C163D98, 0x5FB1298C, 0x9D77B072, 0xABB7661F, 0xBAC1849B, 0x62BCA679 },
    {    0x9E4D4CA8, 0x619E3C32, 0x6271446C, 0xAD5CA17E, 0x48607CB2, 0x53FDC59D, 0x54BF7A57, 0x9E5D5219, 0x9DF36425, 0x6163EDAB, 0x9CD39741, 0x58521D33, 0x9EEFC08A, 0xBAC63E64, 0x9F9C0744, 0x2EE165EE},
    {    0x62BC4B89, 0x9CB212E8, 0x63AC524E, 0x9FB89B42, 0x5881B8F2, 0x6085A0DA, 0x62E657F8, 0x62FA60CB, 0x534C09C4, 0x9DB3E4F8, 0x558EF4CB, 0x619E3BA5, 0x63AE30FB, 0x9DE850A3, 0x51464D33, 0x42617FF5 },
    {   0x9EA60497, 0x9EE76AE0, 0x60D51917, 0xA7855041, 0xA271243F, 0x60B8CA56, 0x9DEA6DC4, 0xB01A7A9F, 0x5BE900BB, 0x63FC553E, 0x60D2DE97, 0x9E7BC09E, 0xB5643AF3, 0x9E254064, 0x506B36B1, 0x60CC44EA },
    {   0xA238DA95, 0x9FC9B4FD, 0x6078BD71, 0xA772F951, 0x5F087D55, 0x6322ED46, 0x9DDFA7FD, 0xA9109FBB, 0x9C32644D, 0x5A9A9427, 0x9FD11CC3, 0x5F04082F, 0x608B9877, 0xA1CBFD60, 0x5CED9A8E, 0xA41FF5CB },
    {   0x9E753352, 0x9FFD7DD4, 0x591E722D, 0xA4F5AFF5, 0x9F3D0C99, 0xA0376ED1, 0x9D674191, 0x5EB32BB0, 0xB44E2E94, 0x599BA5F4, 0x61972DBA, 0x9F16B2AD, 0x58BAEA0E, 0xA38047BD, 0x5977FCE9, 0x6165EB0C },
    {   0x9DD90C1C, 0x511E26CB, 0x6076C4E2, 0xA892476A, 0x5C779292, 0x53879B60, 0x5A1A6E9C, 0x4D90F41A, 0x6134D61E, 0x9D7271FA, 0x9CEA6C0A, 0xA1541C84, 0x5144D587, 0xAEC58852, 0x59C17694, 0xCC00891B },
    {   0x9C569F4D, 0xAD481650, 0x9E272037, 0x5BE3380F, 0x61C5815C, 0x9D85524F, 0xAD94F4F1, 0x62FA6DEC, 0xA2E7298B, 0x625A3FB1, 0x60D0BF79, 0x5D6F141D, 0x9E52741A, 0x5634D706, 0xA43CDA48, 0x9DDA8C95 },
    {   0x9CE2E64C, 0x9CC9BEB0, 0x493BC13B, 0xA300062F, 0x9E1D17DD, 0x56DE8485, 0x60639EDA, 0x607C1D6B, 0xB5636837, 0x9C76C82F, 0x62D84005, 0x63AEEB36, 0x6322EA8A, 0x589DC372, 0x60995288, 0x9D27277E  },
    {   0x9ECB54DB, 0xA7E94B47, 0x3E9070A9, 0x632E85A6, 0x56A3FECE, 0x9EBD9BF3, 0x5AF5749A, 0xBD6FED71, 0xB13B7FA6, 0x9FDA6E86, 0x605A8E56, 0x56470F96, 0xA349329C, 0xACB6382E, 0x4C94B9F0, 0x6178CDE0 }
};

posit32_t C[N_ROW_1][N_COL_2] = { // C is stored in row major layout in memory

    {0x9CE39B2F, 0xA1F589AB, 0xA56262F7, 0x9EC495D3, 0xA416D437, 0x5F884667, 0x9C3C2414, 0x613C1A33, 0x61B46BB3, 0xA7D32235, 0x9E7532CD, 0x54E856A7, 0x9DEA2DC5, 0xA75AD6BC, 0x6355B9D6, 0x63ED6C28},
    {0x605A8AA9, 0xA3E6CB1B, 0x5C02B444, 0x5D2560BE, 0xA9A4CBF2, 0x590451C3, 0x9C2BF0C0, 0x9F584CD8, 0x44D85FC2, 0x9E9EB9B0, 0x9EA78DF6, 0x6161809C, 0x63D37D21, 0x4E54032F, 0x616CD462, 0x63D85B88},
    {0x9E43FA0D, 0xB2C0397A, 0xAA3FD2A0, 0x9D47E1C2, 0x6015D517, 0xAF861238, 0xB84B9EB3, 0x9E692810, 0x9EE51358, 0x62837F16, 0x9CB6E1F7, 0x9FB9C351, 0xA2B1199E, 0xC5F65835, 0x5310A2AB, 0xCA4203CE},
    {0x9D588952, 0x9FE60FD8, 0x617F5689, 0x58CE40D6, 0x598BA875, 0x5AE49C32, 0x6034D9CC, 0x9CEE0329, 0xA7768304, 0x4A1E7852, 0xA5A94562, 0x6182FC47, 0xBF13BE6D, 0x604C4C71, 0x61A1DB06, 0x31D01DF3},
    {0x628D86A7, 0x5326E096, 0x619AB939, 0xA5CC3D56, 0xDE4EFB73, 0x480A8DD2, 0x9DADFF36, 0xAB03C4BF, 0x62AD6A44, 0x585F8E30, 0x9ED71124, 0xA5AFCF8C, 0x9F10CE51, 0x9C65ACF1, 0x62D6E0C7, 0xB2BDB729},
    {0xA3AEA796, 0x549AE68F, 0x9C1DF5C3, 0xA1CB1D3C, 0x5CFE8014, 0x588FAF18, 0x63B57A27, 0x5767E1A5, 0xBC7BA65E, 0x602ED3E9, 0x627407ED, 0x5E1FE1E4, 0x6369502C, 0x608317DB, 0x61DE6B2F, 0x9DD35ECA},
    {0x5EDFDCE3, 0xB0A9A72C, 0x4D9835F7, 0x59DCD05A, 0x63845CDB, 0x63C0D4F2, 0xA27254E2, 0x5EF5D13B, 0x5FFFBAF4, 0xA62CF065, 0x9DFB5EE0, 0x9CA7B800, 0x606FFF59, 0xC573D960, 0x63C4C5C5, 0xB708801C},
    {0x63A58C46, 0xACAE85BF, 0x60B2EC0E, 0x9D5B6B74, 0x4E32BD17, 0x60D53CA5, 0x62CB93FA, 0x61294CE3, 0x9C976E9E, 0xA7DA5AEC, 0x9CC7780D, 0x9DBF9ECA, 0x5B383519, 0x5DA605B5, 0x606128F0, 0x61D8E8F7},
    {0x5F52D85E, 0x60D05EBB, 0x9CC88E2C, 0x9FC0A7EE, 0x579A58A3, 0x61BAE199, 0x9C126EB9, 0x3EFAFE88, 0x5B58AD40, 0x9C79457E, 0xAB5F9E71, 0x6254853E, 0x5AFBB44A, 0x9FCD72DB, 0x61A4FDD3, 0xA6462597},
    {0x61A74CBE, 0xA321E48D, 0x538F9D2E, 0xAACEEEA1, 0xA196BBCF, 0x622F56FB, 0x9F00623C, 0x9D5B6366, 0xA5E22187, 0x5DEDCCBF, 0x60EB3D67, 0x63FADA54, 0xA2F79890, 0xAC37711D, 0x9E306B82, 0x51956745},
    {0x63F6167C, 0x5CDB3C06, 0x542FEF32, 0xAA392683, 0x62A51050, 0xD35ED114, 0x9E265DEC, 0xA7625C5A, 0x9D131D5B, 0x9F3B4E5F, 0x9C485F0F, 0xB40A2711, 0x589C4EC5, 0xA5F880F3, 0xADCF11E4, 0x6358EBD3},
    {0x60080A7B, 0x4A7594A0, 0xA235EAEE, 0x625A1951, 0x9FC2F532, 0xA4D26A51, 0x628B878C, 0x472022E3, 0x5F822325, 0x539D8682, 0x59D1F2B0, 0xA329188A, 0x9FDCA8F3, 0xA4A3B6F1, 0x9E7CB04B, 0x61FD310F},
    {0xA220B7BF, 0x4FBDC4DA, 0x60ABED60, 0x608A8B26, 0xB03A14F4, 0xBBD7FF7A, 0x63EA4C62, 0x5B2C9AE5, 0x6108C252, 0x6270DC6E, 0x6099F7CD, 0x9EF67E9E, 0x4FEA6BD4, 0x9DA15BC5, 0x59C979E3, 0x63491C7B},
    {0x3D09A25F, 0xAF6BA484, 0x9C92CFD9, 0x635B3C88, 0x9DA5E624, 0x9CA8428D, 0x9FEFE38B, 0x9D0C69A4, 0xB4829A59, 0x403CA909, 0xA4012563, 0x9CD0BBF0, 0x9DC91D78, 0xA9377080, 0x9CF7ECAE, 0x5CAF23F5},
    {0x9F4FF4C5, 0xA35523FD, 0xAA72B6A6, 0xAD5376E7, 0x9C06CD61, 0x9DCB0A4D, 0x61CDE237, 0x9C050CF6, 0x385D05F8, 0xC5400395, 0xA5516A2C, 0xAF35B94B, 0x607D42A6, 0x61759204, 0xA0A98CF0, 0xA4A3AEF2},
    {0x9FE135B3, 0xBDB0A7D8, 0x5BBA8143, 0x9FA6EC7D, 0xA52AC63F, 0x62E2DAFB, 0x9CC6F097, 0xB5F4FF31, 0x5D8A2ABD, 0x9E684277, 0x9CC20B43, 0x9E3616D6, 0x62B37FF3, 0x9C25ED96, 0x9F035DE7, 0x9C802324}

};

volatile posit32_t D[N_ROW_1][N_COL_2] = { // D is stored in row-major layout in memory

    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000},
    {0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000}

};


int main() {

    int hart_ID;
    
    /*
     * Enable interrupts / Klessydra runtime support.
     */
    __asm__ volatile ("csrw 0x300, 0x8;" ::: "memory");

    hart_ID = Klessydra_get_coreID();

    /*
     * Harts 0, 1, and 2 independently load the first four
     * FP16 elements of their corresponding row of A.
     *
     * hart 0 -> A[0][0..3]
     * hart 1 -> A[1][0..3]
     * hart 2 -> A[2][0..3]
     */
    if (hart_ID < 16) {  // we have at most 16 threads available. so we use the register files to load the 
                         // elements related to octect 0 and octect 1 as described in "Modeling Deep Learning Accelerator Enabled GPUs" research paper...
                         // so, klessydra Register FIles 0 to 3 and register files 8 to 11 have elements related to octect 0 described in the above mentioneed paper,
                         // and klessydra register files 4 to 7 and register files 12 to 15 contain elements related to octect 1 described in the above mentioned paper. 


    uint32_t virtual_tid = hart_ID + ((hart_ID >> 3) << 3);

    /*
    * POSIT32 offset mapping derived from the FlexGrip Plus POSIT32 benchmark.
    *
    * One POSIT32 element = 4 bytes.
    * One 16-element POSIT32 row = 64 bytes.
    *
    * virtual_tid maps the 16 Klessydra harts onto the FlexGrip thread
    * positions that compute all 16 rows for columns 0..7.
    * The assembly block then manually computes columns 8..15 by using:
    *
    *   C/D + 32 bytes
    *   B_T + 512 bytes
    */

    uint32_t A_offset =
        ((virtual_tid & 0x3) << 6)
        + ((virtual_tid >> 4) << 8)
        + (((virtual_tid >> 2) & 0x1) << 9);

    uint32_t B_offset =
        ((virtual_tid & 0x3) << 6)
        + (((virtual_tid >> 3) & 0x1) << 9)
        + ((virtual_tid >> 4) << 8);

    uint32_t C_offset =
        ((virtual_tid & 0x3) << 6)
        + ((virtual_tid >> 4) << 8)
        + (((virtual_tid >> 2) & 0x1) << 9)
        + (((virtual_tid >> 3) & 0x1) << 5);

    uint8_t *A_base_byte = (uint8_t *)A;
    uint32_t *A_ptr = (uint32_t *)(A_base_byte + A_offset);

    uint8_t *B_base_byte = (uint8_t *)B_T;
    uint32_t *B_ptr = (uint32_t *)(B_base_byte + B_offset);

    uint8_t *C_base_byte = (uint8_t *)C;
    uint32_t *C_ptr = (uint32_t *)(C_base_byte + C_offset);

    uint8_t *D_base_byte = (uint8_t *)D;
    uint32_t *D_ptr = (uint32_t *)(D_base_byte + C_offset);

    __asm__ volatile (

        // ============================================================
        // FIRST OUTPUT HALF: D columns 0..7
        // ============================================================

        // Load C accumulators for columns 0..7
        "lw x5,    0(%[baseC])\n"
        "lw x6,    4(%[baseC])\n"
        "lw x7,    8(%[baseC])\n"
        "lw x8,   12(%[baseC])\n"

        "lw x9,   16(%[baseC])\n"
        "lw x10,  20(%[baseC])\n"
        "lw x11,  24(%[baseC])\n"
        "lw x12,  28(%[baseC])\n"

        // ------------------------------------------------------------
        // Batch 1: k = 0..7
        // ------------------------------------------------------------

        // Load A chunk 0: A[k=0..3] -> x13..x16
        "lw x13,   0(%[baseA])\n"
        "lw x14,   4(%[baseA])\n"
        "lw x15,   8(%[baseA])\n"
        "lw x16,  12(%[baseA])\n"

        // Load A chunk 1: A[k=4..7] -> x17..x20
        "lw x17,  16(%[baseA])\n"
        "lw x18,  20(%[baseA])\n"
        "lw x19,  24(%[baseA])\n"
        "lw x20,  28(%[baseA])\n"

        // Load B chunk 0 -> x21..x24
        "lw x21,   0(%[baseB])\n"
        "lw x22,   4(%[baseB])\n"
        "lw x23,   8(%[baseB])\n"
        "lw x24,  12(%[baseB])\n"

        // Load B chunk 1 -> x25..x28
        "lw x25,  16(%[baseB])\n"
        "lw x26,  20(%[baseB])\n"
        "lw x27,  24(%[baseB])\n"
        "lw x28,  28(%[baseB])\n"

        HMMA_0_POSIT32_ASM(x5, x13, x21)
        HMMA_1_POSIT32_ASM(x9, x13, x21)

        HMMA_0_POSIT32_ASM(x5, x17, x25)
        HMMA_1_POSIT32_ASM(x9, x17, x25)  //at this point, set0 and set 1 hmma instructions are done. relating to the first half of the computation of the
                                       //final first part of the final D matrix (D[0-15][0-7])
                                       //the reason for this split is because in this core it is not possible to allocate registers for the execution of the other 
                                       //4 hmma instruction  (for the completion of the D[0-15][0-7] result, hence there will be now a new loading phase for the A and B related elements 
                                       // so that the final 4 hmma instructions (set 1 and set2 ) will complete the first part of the final D[0-15][0-7])
        
                                       // ------------------------------------------------------------
        // Batch 2: k = 8..15
        // Reuse the same A/B registers.
        // ------------------------------------------------------------

        // Load A chunk 2: A[k=8..11] -> x13..x16
        "lw x13,  32(%[baseA])\n"
        "lw x14,  36(%[baseA])\n"
        "lw x15,  40(%[baseA])\n"
        "lw x16,  44(%[baseA])\n"

        // Load A chunk 3: A[k=12..15] -> x17..x20
        "lw x17,  48(%[baseA])\n"
        "lw x18,  52(%[baseA])\n"
        "lw x19,  56(%[baseA])\n"
        "lw x20,  60(%[baseA])\n"

        // Load B chunk 2 -> x21..x24
        "lw x21,  32(%[baseB])\n"
        "lw x22,  36(%[baseB])\n"
        "lw x23,  40(%[baseB])\n"
        "lw x24,  44(%[baseB])\n"

        // Load B chunk 3 -> x25..x28
        "lw x25,  48(%[baseB])\n"
        "lw x26,  52(%[baseB])\n"
        "lw x27,  56(%[baseB])\n"
        "lw x28,  60(%[baseB])\n"

        HMMA_0_POSIT32_ASM(x5, x13, x21)
        HMMA_1_POSIT32_ASM(x9, x13, x21)

        HMMA_0_POSIT32_ASM(x5, x17, x25)
        HMMA_1_POSIT32_ASM(x9, x17, x25)  
        
        // Store D columns 0..7
        "sw x5,    0(%[baseD])\n"
        "sw x6,    4(%[baseD])\n"
        "sw x7,    8(%[baseD])\n"
        "sw x8,   12(%[baseD])\n"

        "sw x9,   16(%[baseD])\n"
        "sw x10,  20(%[baseD])\n"
        "sw x11,  24(%[baseD])\n"
        "sw x12,  28(%[baseD])\n"      //at this point, the 16 threads complete the final first half of the matrix D[0-15][0-7]
                                       //and the next subsequent assembly instruction will be needed for these 16 threads to prepare the 
                                       // last part of the final D matrix ( D[0-15][8-15] ). 
                                       // again i remind that this is like so, because it is not possible to execute more then 16 threads
                                       // on this core... so these same 16 threads which calculated D[0-15][0-7] have to also do the work 
                                       // that octect 2 and 3 do in the talked research paper , which is the duty of calculating the second part of the D
                                       // final matrix ( D[0-15][8-15] )
                                       
        // ============================================================
        // SECOND OUTPUT HALF: D columns 8..15
        // ============================================================

        // Load C accumulators for columns 8..15
        "lw x5,   32(%[baseC])\n"
        "lw x6,   36(%[baseC])\n"
        "lw x7,   40(%[baseC])\n"
        "lw x8,   44(%[baseC])\n"

        "lw x9,   48(%[baseC])\n"
        "lw x10,  52(%[baseC])\n"
        "lw x11,  56(%[baseC])\n"
        "lw x12,  60(%[baseC])\n"                               

        // ------------------------------------------------------------
        // Batch 1: k = 0..7, B second half starts at +512 bytes
        // ------------------------------------------------------------

        // Load A chunk 0: A[k=0..3] -> x13..x16
        "lw x13,   0(%[baseA])\n"
        "lw x14,   4(%[baseA])\n"
        "lw x15,   8(%[baseA])\n"
        "lw x16,  12(%[baseA])\n"

        // Load A chunk 1: A[k=4..7] -> x17..x20
        "lw x17,  16(%[baseA])\n"
        "lw x18,  20(%[baseA])\n"
        "lw x19,  24(%[baseA])\n"
        "lw x20,  28(%[baseA])\n"

        // Load B second-half chunk 0 -> x21..x24
        "lw x21, 512(%[baseB])\n"
        "lw x22, 516(%[baseB])\n"
        "lw x23, 520(%[baseB])\n"
        "lw x24, 524(%[baseB])\n"

        // Load B second-half chunk 1 -> x25..x28
        "lw x25, 528(%[baseB])\n"
        "lw x26, 532(%[baseB])\n"
        "lw x27, 536(%[baseB])\n"
        "lw x28, 540(%[baseB])\n"

        HMMA_0_POSIT32_ASM(x5, x13, x21)
        HMMA_1_POSIT32_ASM(x9, x13, x21)

        HMMA_0_POSIT32_ASM(x5, x17, x25)
        HMMA_1_POSIT32_ASM(x9, x17, x25)  //at this point , the 16 threads are done calculating the first part of 
                                       // the second half of that final D matrix ( D[0-15][8-15] ).
                                       //reminder that this split in the execution has been designed in the program flow due
                                       //to space contraints of registers in the present target core (klessydra T13 riscV). 
        // ------------------------------------------------------------
        // Batch 2: k = 8..15, B second half
        // ------------------------------------------------------------

        // Load A chunk 2: A[k=8..11] -> x13..x16
        "lw x13,  32(%[baseA])\n"
        "lw x14,  36(%[baseA])\n"
        "lw x15,  40(%[baseA])\n"
        "lw x16,  44(%[baseA])\n"

        // Load A chunk 3: A[k=12..15] -> x17..x20
        "lw x17,  48(%[baseA])\n"
        "lw x18,  52(%[baseA])\n"
        "lw x19,  56(%[baseA])\n"
        "lw x20,  60(%[baseA])\n"

        // Load B second-half chunk 2 -> x21..x24
        "lw x21, 544(%[baseB])\n"
        "lw x22, 548(%[baseB])\n"
        "lw x23, 552(%[baseB])\n"
        "lw x24, 556(%[baseB])\n"

        // Load B second-half chunk 3 -> x25..x28
        "lw x25, 560(%[baseB])\n"
        "lw x26, 564(%[baseB])\n"
        "lw x27, 568(%[baseB])\n"
        "lw x28, 572(%[baseB])\n"

        HMMA_0_POSIT32_ASM(x5, x13, x21)
        HMMA_1_POSIT32_ASM(x9, x13, x21)

        HMMA_0_POSIT32_ASM(x5, x17, x25)
        HMMA_1_POSIT32_ASM(x9, x17, x25)


        // Store D columns 8..15
        "sw x5,   32(%[baseD])\n"
        "sw x6,   36(%[baseD])\n"
        "sw x7,   40(%[baseD])\n"
        "sw x8,   44(%[baseD])\n"

        "sw x9,   48(%[baseD])\n"
        "sw x10,  52(%[baseD])\n"
        "sw x11,  56(%[baseD])\n"
        "sw x12,  60(%[baseD])\n"  // at this point, the storage of the final second part of the final D matrix 
                                   // (D[0-15][8-15] ) is finished, and since the first part was stored in memory before,
                                   // the final D matrix is computed and located in memory in row major layout.                          


        :
        : [baseA] "r" (A_ptr),
          [baseB] "r" (B_ptr),
          [baseC] "r" (C_ptr),
          [baseD] "r" (D_ptr)
        : "x5",  "x6",  "x7",  "x8",
          "x9",  "x10", "x11", "x12",
          "x13", "x14", "x15", "x16",
          "x17", "x18", "x19", "x20",
          "x21", "x22", "x23", "x24",
          "x25", "x26", "x27", "x28",
          "memory"

    );

}

    return 0;
}