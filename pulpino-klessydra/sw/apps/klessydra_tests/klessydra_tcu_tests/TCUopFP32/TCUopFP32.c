#include <stdio.h>

#include <stdint.h>

#include "functions.h"
#include "KTCU_hmma.h"

#define N_ROW_1 16

#define N_COL_1 16

#define N_COL_2 16

typedef uint32_t fp32_t;
fp32_t A[N_ROW_1][N_COL_1] = { //A is stored in row major layout

    { 0x418C43F8, 0xC07A5A9A, 0x41B79A26, 0x414A1AD8, 0xC1CFC7FD, 0x41F384C6, 0x4185B41A, 0x41927705, 0xC1BE67E4, 0xC04B381D, 0xC1044D86, 0x41DA80F1, 0x41135161, 0x41A54103, 0xC067C683, 0xC18BA75E },

    { 0x405F944C, 0xC1DF5358, 0x41A7BF46, 0x4106D308, 0x41842414, 0xC114F725, 0x41F0FF55, 0x41C9472C, 0x418E8848, 0xC19C5851, 0xC0084F8F, 0xC1E9928E, 0xC1B100F8, 0x413B712F, 0x417AA2EE, 0x41EF5D70 },

    { 0xC1325AD6, 0xC104A636, 0xBFF96617, 0xC19EFD9C, 0xC1BD7AEE, 0xBFC70676, 0xC18BD28A, 0x412DE3B8, 0xC080B67F, 0x41AA54CC, 0x414D124B, 0xC14022F6, 0x41AA1DF5, 0x419C0A13, 0xC0E671BC, 0xC158C084 },

    { 0x413AE01A, 0xC1B8725D, 0xC199A5A2, 0xC1FC3B03, 0x4192E7C1, 0x4128CEAA, 0x415216DF, 0x418FBBB7, 0xC02847EF, 0x408CC82F, 0xC1B86C87, 0xC1C55C50, 0x412C71D3, 0xBFECC7A6, 0x40859A82, 0x4187ADEE },

    { 0x4109F399, 0x405B7613, 0x40728335, 0xC148C14E, 0xC1F038A5, 0xC0819A50, 0xC19221F5, 0xC0BB5556, 0x41B4F13F, 0xC1883915, 0xC1E22625, 0xC15FDCE7, 0xC1535C28, 0x4125CD71, 0x40699A8C, 0x41915B1B },

    { 0x412841CF, 0xC0BFB83F, 0x41A0C748, 0xC1AA8287, 0xC1F45F15, 0xC1D1E53F, 0x4163B22B, 0xC01C269F, 0xC1AD6DC9, 0x3D88F0D6, 0xC1B20426, 0x41490835, 0xC05C8B3D, 0xC0F3AB25, 0xC14B406A, 0x410568CD },

    { 0xC10D80FF, 0xC1D31F8D, 0xC1C394BB, 0x41EC7DDA, 0x41D1317D, 0x414C8007, 0xC16FBFC9, 0x41F037E3, 0x418EB870, 0x415E1876, 0xC04F6A50, 0xC1693982, 0xC1CEA5D8, 0x41CE21E7, 0xC03523EC, 0xC19863D4 },

    { 0xC146B34F, 0x40A23DDF, 0xC1A57E0A, 0x41B69626, 0x41845CAC, 0x4160BAE6, 0xC08B12CE, 0x41025D40, 0x40AC3B8E, 0x41197163, 0xC1D4C3B7, 0xC0AC6D2B, 0xC1EAB18C, 0xBEC4E8A9, 0xC12E38DD, 0xC1B600ED },

    { 0xC1CB0EC4, 0x40B37EFF, 0xC1A8A80A, 0x41D9A958, 0x40A60362, 0xC11CCE29, 0x40BA31E7, 0xC1F4530D, 0x41EAC846, 0xBF90F862, 0x4190C2AC, 0xC1D5A46A, 0xBF5A9704, 0xBF1841B1, 0x41E02ACA, 0x4092E628 },

    { 0xBFD92CC1, 0xC16E9DEF, 0xC12C792D, 0x3FA9592C, 0xC07A37FA, 0xC1F4EF43, 0x41A70FBC, 0x41CAD596, 0xC1B83145, 0x405D5501, 0xC1C868C3, 0x41305FB5, 0xC1600440, 0x41233FB0, 0x41687147, 0x41898C2A },

    { 0xC1C8D62E, 0x41D4FF81, 0xC18A2164, 0xC1ECD843, 0x4060ACFC, 0xC1042CF3, 0x41A8DA34, 0x419DD323, 0xC13B3FF1, 0x41E7E26E, 0xC15619A2, 0x3F76B22D, 0xC179E44A, 0x41DF411A, 0xC1ABB886, 0xC1E9017A },

    { 0xC084EBD5, 0x41FC18A6, 0x41C889EC, 0x417E931A, 0x41C815F4, 0x41C971D7, 0x3F9A7CD9, 0xC13C7D18, 0x418B4537, 0x41258A88, 0xC1015FDE, 0xC1CFA211, 0x417CB66A, 0xC1733D8D, 0x41DFA5F9, 0xC1849F81 },

    { 0xC1C125DF, 0x41A9879A, 0xC1B184B8, 0xC1A436F2, 0x40CB8934, 0x41BFC699, 0xC19B6CEA, 0xC1423A83, 0x418E0802, 0x41F1933C, 0x3D424C2A, 0xC1B65311, 0xC1F8DD58, 0xC18A6A86, 0xC1BC81CC, 0x4135EC28 },

    { 0xC1C19F2C, 0x3ECF6B51, 0x4146ECBB, 0x40A62077, 0xC199B701, 0x419BB636, 0x415C93B0, 0x4174B839, 0xC1BCE600, 0xC1C0A357, 0x41DAE97B, 0xC0D1C286, 0xC14BD41B, 0xBF3B09FC, 0x4126C5E0, 0x41E94774 },

    { 0xC15AADD7, 0x41D9807E, 0xC1F3459E, 0x40621758, 0x410930C6, 0xC1C9C7D1, 0xC1B82569, 0xC0A5A764, 0x41EEB5F3, 0x40C4B1F5, 0x41DDB538, 0x419BD532, 0xC0059ADF, 0x4191CC84, 0xC1F6DE19, 0xC1C81E47 },

    { 0x41A8AADE, 0x4197F869, 0xC188E350, 0x3FFC1082, 0x40D91ED3, 0x41BC4848, 0x40D329D8, 0xC0B30DAD, 0xC100D5E6, 0xC097CB22, 0x411B93CF, 0x41BC27BB, 0xC03CD69F, 0xC1811B2C, 0xC186D431, 0x417BEB2B }

};
fp32_t B_T[N_COL_2][N_COL_1] = { //B is stored in column major layout in memory (so this below is B transpose)

    { 0x41A2154D, 0xC1E4AB20, 0x3FC2958B, 0x41B713B2, 0x41D52B91, 0xC1CF4F9C, 0x408504D4, 0xC12A5ADD, 0xC0FD373F, 0xC14AD38C, 0xC1B6C5D6, 0x414AE02D, 0xC1E41889, 0x409FC77D, 0xC0BACFEC, 0xC08C749E },

    { 0xC1CA18FE, 0x40BAA99C, 0xC1CBF1A9, 0xC0185FB1, 0xBF9C61BC, 0x416721FF, 0x40945673, 0x41CBF6B3, 0x41F927C5, 0x41D63E04, 0x418DB487, 0x41AD0BBE, 0x40EE3366, 0x414C9211, 0xC19092FE, 0x4101096A },

    { 0xC1DDEBFF, 0x41390D3B, 0x41AABB14, 0xC0EB5633, 0xC12FC215, 0xC1D4BD4E, 0xC00B5327, 0x41866A9D, 0x415EFC8A, 0x419005C6, 0xC19A84FA, 0xC1EB714A, 0xC1EA5107, 0x4118D094, 0x40B4D9E8, 0xC10EAFD8 },

    { 0x40C16670, 0xC0D9D846, 0xC1E56541, 0x410EE9AD, 0x40112412, 0x41DF3381, 0x3FB96646, 0xC16AF8E3, 0x41E702FD, 0xC1C760F5, 0x41D23F2C, 0xC198B004, 0x41C4AEBF, 0x41E19597, 0xC13B59A1, 0x3F50B844 },

    { 0xC1B528C8, 0xC13A608B, 0x41D984E0, 0xC16F243D, 0x41B27685, 0xC1B9A5AB, 0x418720F7, 0xC10B113F, 0xC1C356C7, 0x41FE7B54, 0x412004FE, 0xC1C00A01, 0x41569BB1, 0xC1B3FFCE, 0xC1ED8991, 0x417262FA },

    { 0x41A63A63, 0x3E9450D4, 0xC1CD410B, 0xC1B87046, 0x411C3FDB, 0x41EAF25A, 0x4199369A, 0xC13E0372, 0x41B37927, 0x41C22681, 0xC1ED7C15, 0x3E9478B3, 0xC1A75BC9, 0x3F08D9ED, 0xC0A71DE1, 0x41C5D699 },

    { 0xC14237A1, 0x41C000A6, 0x41AFE90E, 0xBFB53AB8, 0x419BD93F, 0x419A0D7E, 0xBF008FCD, 0xC1AF4D87, 0x410C5D19, 0xC15D471B, 0xC1FD384D, 0x417B1299, 0xC1D109F2, 0xC0C4899E, 0xBFD3E7B6, 0x41D794CF },

    { 0xC1B6566B, 0x41B3C786, 0x41CE288E, 0xC0AA35E8, 0x400607CB, 0x40BFDC5A, 0x40CBF7A5, 0xC1B455BD, 0xC1C1937B, 0x41AC7DB5, 0xC1E58D18, 0x410521D3, 0xC1A207EF, 0xBFD39C1A, 0xC18C7F17, 0x3E6E165F },

    { 0x41D78971, 0xC1E9BDA3, 0x41F58A4A, 0xC188EC98, 0x41081B8F, 0x4190B41B, 0x41DCCAFF, 0x41DF4C19, 0x40B4C09C, 0xC1C98361, 0x40D8EF4D, 0x41B3C775, 0x41F5C61F, 0xC1C2F5EC, 0x409464D3, 0x3FA617FF },

    { 0xC1AB3F6D, 0xC1A312A4, 0x419AA323, 0xC107AAFC, 0xC158EDBC, 0x4197194B, 0xC1C2B247, 0xC07E5856, 0x413E900C, 0x41FF8AA8, 0x419A5BD3, 0xC1B087EC, 0xC029BC51, 0xC1BB57F4, 0x4086B36B, 0x4199889D },

    { 0xC15C7257, 0xC186C960, 0x418F17AE, 0xC108D06B, 0x417087D5, 0x41E45DA9, 0xC1C40B00, 0xC0EEF604, 0xC1F9B376, 0x4129A942, 0xC185DC68, 0x41704083, 0x4191730F, 0xC163402A, 0x414ED9A9, 0xC13E00A3 },

    { 0xC1B15996, 0xC1805046, 0x4111E723, 0xC130A501, 0xC1985E6D, 0xC17C8913, 0xC1D317CE, 0x416B32BB, 0xC03B1D17, 0x4119BA5F, 0x41B2E5B7, 0xC19D29AA, 0x410BAEA1, 0xC147FB84, 0x41177FCF, 0x41ACBD62 },

    { 0xC1C4DE7D, 0x4091E26D, 0x418ED89C, 0xC0F6DB89, 0x41477929, 0x40B879B6, 0x4121A6EA, 0x40590F42, 0x41A69AC4, 0xC1D1B1C1, 0xC1E2B27F, 0xC16ABE38, 0x40944D58, 0xC093A77B, 0x411C1769, 0xBEBFF76E },

    { 0xC1F52C16, 0xC0AB7E9B, 0xC1BB1BF9, 0x413E3381, 0x41B8B02B, 0xC1CF55B6, 0xC0A6B0B1, 0x41DF4DBE, 0xC1518D67, 0x41CB47F6, 0x419A17EF, 0x4156F142, 0xC1B5B17D, 0x40E34D70, 0xC13C325B, 0xC1C4AE6D },

    { 0xC1E3A337, 0xC1E6C82A, 0x4013BC14, 0xC14FFF9D, 0xC1BC5D04, 0x40EDE848, 0x418C73DB, 0x418F83AD, 0xC029C97D, 0xC1F126FA, 0x41DB0801, 0x41F5DD67, 0x41E45D51, 0x4109DC37, 0x41932A51, 0xC1DB1B10 },

    { 0xC1A69565, 0xC1016B4C, 0x3F69070B, 0x41E5D0B5, 0x40EA3FED, 0xC1A84C82, 0x412F574A, 0xBFA90129, 0xC06C4806, 0xC184B22F, 0x418B51CB, 0x40E470F9, 0xC14B6CD6, 0xC0B49C7D, 0x40494B9F, 0x41AF19BC }

};
fp32_t C[N_ROW_1][N_COL_2] = { // C is stored in row major layout in memory

    { 0xC1E38C9A, 0xC160A765, 0xC129D9D1, 0xC1A76D46, 0xC13E92BD, 0x41788466, 0xC1F87B7E, 0x41A78346, 0x41B68D76, 0xC102CDDD, 0xC1B159A6, 0x40CE856A, 0xC1C2BA47, 0xC10A5294, 0x41EAB73B, 0x41FDAD85 },

    { 0x418B5155, 0xC141934E, 0x41402B44, 0x4152560C, 0xC0E5B341, 0x4110451C, 0xC1FA81E8, 0xC194F665, 0x3FCD85FC, 0xC1AC28CA, 0xC1AB0E41, 0x41AC3013, 0x41FA6FA4, 0x40654033, 0x41AD9A8C, 0x41FB0B71 },

    { 0xC1B780BE, 0xC053FC68, 0xC0DC02D6, 0xC1D703C8, 0x4182BAA3, 0xC0879EDC, 0xBFFB4615, 0xC1B2DAFE, 0xC1A35D95, 0x41D06FE3, 0xC1E923C1, 0xC188C796, 0xC154EE66, 0xBF209A7D, 0x40B10A2B, 0xBEDBDFC3 },

    { 0xC1D4EED6, 0xC1833E05, 0x41AFEAD1, 0x410CE40D, 0x4118BA87, 0x412E49C3, 0x41869B39, 0xC1E23F9B, 0xC10897D0, 0x4021E785, 0xC1256BAA, 0x41B05F89, 0xBF8EC419, 0x4189898E, 0x41B43B61, 0x3E9D01DF },

    { 0x41D1B0D5, 0x40B26E09, 0x41B35727, 0xC1233C2B, 0xBD9B1049, 0x4000A8DD, 0xC1CA4019, 0xC0CFC3B4, 0x41D5AD49, 0x4105F8E3, 0xC1A51DDB, 0xC1250307, 0xC19DE636, 0xC1F34A62, 0x41DADC19, 0xC054248D },

    { 0xC1451587, 0x40C9AE69, 0xC1FC4148, 0xC1634E2C, 0x414FE801, 0x4108FAF2, 0x41F6AF45, 0x40F67E1A, 0xBFB8459A, 0x4185DA7D, 0x41CE80FE, 0x4161FE1E, 0x41ED2A06, 0x419062FB, 0x41BBCD66, 0xC1C59427 },

    { 0x416DFDCE, 0xC075658D, 0x4059835F, 0x411DCD06, 0x41F08B9B, 0x41F81A9E, 0xC158DAB2, 0x416F5D14, 0x417FFBAF, 0xC11D30FA, 0xC1C09424, 0xC1EB0900, 0x418DFFEB, 0xBF28C26A, 0x41F898B9, 0xC00F77FE },

    { 0x41F4B189, 0xC0B517A4, 0x41965D82, 0xC1D49291, 0x40632BD1, 0x419AA795, 0x41D9727F, 0x41A5299C, 0xC1ED122C, 0xC1025A51, 0xC1E710FE, 0xC1C80C27, 0x41338352, 0x415A605B, 0x418C251E, 0x41BB1D1F },

    { 0x41752D86, 0x419A0BD7, 0xC1E6EE3B, 0xC187EB02, 0x40F9A58A, 0x41B75C33, 0xC1FDB229, 0x3F6FAFE8, 0x41358AD4, 0xC1F0D750, 0xC0CA0619, 0x41CA90A8, 0x412FBB45, 0xC18651A5, 0x41B49FBA, 0xC11B9DA7 },

    { 0x41B4E998, 0xC14DE1B7, 0x40B8F9D3, 0xC0D31116, 0xC1669443, 0x41C5EADF, 0xC19FF3B9, 0xC1D49393, 0xC121DDE8, 0x415EDCCC, 0x419D67AD, 0x41FF5B4A, 0xC1508677, 0xC0BC88EE, 0xC1B9F290, 0x40995674 },

    { 0x41FEC2D0, 0x414DB3C0, 0x40C2FEF3, 0xC0DC6D98, 0x41D4A20A, 0xBE4A12EF, 0xC1BB3443, 0xC109DA3A, 0xC1DD9C55, 0xC1989634, 0xC1F6F41E, 0xC03F5D8F, 0x4109C4EC, 0xC12077F1, 0xC0A30EE2, 0x41EB1D7A },

    { 0x4181014F, 0x4027594A, 0xC15CA151, 0x41CB432A, 0xC187A15A, 0xC132D95B, 0x41D170F1, 0x3FF2022E, 0x41782232, 0x40B9D868, 0x411D1F2B, 0xC14D6E77, 0xC1846AE2, 0xC135C491, 0xC1B069F7, 0x41BFA622 },

    { 0xC15DF484, 0x407BDC4E, 0x41957DAC, 0x41915165, 0xC07C5EB1, 0xBFC28008, 0x41FD498C, 0x4132C9AE, 0x41A1184A, 0x41CE1B8E, 0x41933EFA, 0xC1A1302C, 0x407EA6BD, 0xC1CBD487, 0x411C979E, 0x41E9238F },

    { 0x3F509A26, 0xC08945B8, 0xC1EDA605, 0x41EB6791, 0xC1CB433B, 0xC1EAF7AE, 0xC182038F, 0xC1DE72CC, 0xC037D65A, 0x3F83CA91, 0xC13FEDAA, 0xC1E5E882, 0xC1C6DC51, 0xC0EC88F8, 0xC1E1026A, 0x414AF23F },

    { 0xC1960167, 0xC14AADC0, 0xC0D8D496, 0xC0AAC892, 0xC1FF2654, 0xC1C69EB6, 0x41B9BC47, 0xC1FF5E61, 0x3F05D060, 0xBF2BFFC7, 0xC12AE95D, 0xC08CA46B, 0x418FA855, 0x41AEB241, 0xC1756731, 0xC135C511 },

    { 0xC183D94A, 0xBFA4F583, 0x413BA814, 0xC18B2270, 0xC12D539C, 0x41DC5B5F, 0xC1E721ED, 0xC020B00D, 0x4158A2AC, 0xC1B2F7B1, 0xC1E7BE98, 0xC1B93D25, 0x41D66FFE, 0xC1FB424D, 0xC19F9443, 0xC1EFFB9B }

};
volatile fp32_t D[N_ROW_1][N_COL_2] = { // D is stored in row-major layout in memory

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 },

    { 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000 }

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
    * FP32 offset mapping derived from the FlexGrip Plus FP32 benchmark.
    *
    * One FP32 element = 4 bytes.
    * One 16-element FP32 row = 64 bytes.
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

        HMMA_0_FP32_ASM(x5, x13, x21)
        HMMA_1_FP32_ASM(x9, x13, x21)

        HMMA_0_FP32_ASM(x5, x17, x25)
        HMMA_1_FP32_ASM(x9, x17, x25)  //at this point, set0 and set 1 hmma instructions are done. relating to the first half of the computation of the
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

        HMMA_0_FP32_ASM(x5, x13, x21)
        HMMA_1_FP32_ASM(x9, x13, x21)

        HMMA_0_FP32_ASM(x5, x17, x25)
        HMMA_1_FP32_ASM(x9, x17, x25)  
        
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

        HMMA_0_FP32_ASM(x5, x13, x21)
        HMMA_1_FP32_ASM(x9, x13, x21)

        HMMA_0_FP32_ASM(x5, x17, x25)
        HMMA_1_FP32_ASM(x9, x17, x25)  //at this point , the 16 threads are done calculating the first part of 
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

        HMMA_0_FP32_ASM(x5, x13, x21)
        HMMA_1_FP32_ASM(x9, x13, x21)

        HMMA_0_FP32_ASM(x5, x17, x25)
        HMMA_1_FP32_ASM(x9, x17, x25)


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