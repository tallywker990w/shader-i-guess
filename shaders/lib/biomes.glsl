uniform int biome;
bool auroraBiomeOn(){
#ifdef AURORA_ALL_BIOMES
    return true;
#else
    bool r = false;
#ifdef AB_SNOWY_PLAINS
    r = r || biome == 1000;
#endif
#ifdef AB_ICE_SPIKES
    r = r || biome == 1001;
#endif
#ifdef AB_SNOWY_TAIGA
    r = r || biome == 1002;
#endif
#ifdef AB_SNOWY_SLOPES
    r = r || biome == 1003;
#endif
#ifdef AB_GROVE
    r = r || biome == 1004;
#endif
#ifdef AB_FROZEN_PEAKS
    r = r || biome == 1005;
#endif
#ifdef AB_JAGGED_PEAKS
    r = r || biome == 1006;
#endif
#ifdef AB_TAIGA
    r = r || biome == 1007;
#endif
#ifdef AB_OLD_GROWTH_PINE_TAIGA
    r = r || biome == 1008;
#endif
#ifdef AB_OLD_GROWTH_SPRUCE_TAIGA
    r = r || biome == 1009;
#endif
#ifdef AB_SNOWY_BEACH
    r = r || biome == 1010;
#endif
#ifdef AB_FROZEN_RIVER
    r = r || biome == 1011;
#endif
#ifdef AB_FROZEN_OCEAN
    r = r || biome == 1012;
#endif
#ifdef AB_DEEP_FROZEN_OCEAN
    r = r || biome == 1013;
#endif
#ifdef AB_CUSTOM_1
    r = r || biome == 9001;
#endif
#ifdef AB_CUSTOM_2
    r = r || biome == 9002;
#endif
#ifdef AB_CUSTOM_3
    r = r || biome == 9003;
#endif
#ifdef AB_CUSTOM_4
    r = r || biome == 9004;
#endif
    return r;
#endif
}
