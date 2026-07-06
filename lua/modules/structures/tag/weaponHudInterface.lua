return { {
    address = "0x0",
    fields = { {
        address = "0x0",
        is = "int",
        metaName = "TagGroup",
        name = "tagGroup",
        offset = 0,
        size = 4,
        type = "int",
        what = "field"
      }, {
        address = "0x4",
        count = 4,
        elementSize = 1,
        elementType = "char",
        is = "ptr",
        name = "path",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "pathSize",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        fields = { {
            address = "0x0",
            is = "int",
            name = "value",
            offset = 0,
            size = 4,
            type = "dword",
            unsigned = true,
            what = "field"
          }, {
            address = "0x0",
            is = "int",
            name = "index",
            offset = 0,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "id",
            offset = 2,
            size = 2,
            type = "word",
            unsigned = true,
            what = "field"
          } },
        is = "union",
        metaName = "TableResourceHandle",
        name = "tagHandle",
        offset = 12,
        size = 4,
        type = "TableResourceHandle",
        what = "field"
      } },
    is = "struct",
    metaName = "TagReference",
    name = "childHud",
    offset = 0,
    size = 16,
    type = "TagReference",
    what = "field"
  }, {
    address = "0x10",
    fields = { {
        address = "0x0",
        is = "int",
        name = "useParentHudFlashingParameters",
        offset = 0,
        size = 2,
        type = "word",
        unsigned = true,
        what = "bitfield"
      } },
    is = "struct",
    metaName = "WeaponHUDInterfaceFlags",
    name = "flags",
    offset = 16,
    size = 2,
    type = "WeaponHUDInterfaceFlags",
    what = "field"
  }, {
    address = "0x12",
    count = 2,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad10084",
    offset = 18,
    size = 2,
    what = "field"
  }, {
    address = "0x14",
    is = "int",
    name = "totalAmmoCutoff",
    offset = 20,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x16",
    is = "int",
    name = "loadedAmmoCutoff",
    offset = 22,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x18",
    is = "int",
    name = "heatCutoff",
    offset = 24,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x1a",
    is = "int",
    name = "ageCutoff",
    offset = 26,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x1c",
    count = 32,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad10219",
    offset = 28,
    size = 32,
    what = "field"
  }, {
    address = "0x3c",
    is = "int",
    metaName = "HUDInterfaceAnchor",
    name = "anchor",
    offset = 60,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x3e",
    is = "int",
    metaName = "HUDInterfaceCanvasSize",
    name = "canvasSize",
    offset = 62,
    size = 2,
    type = "short",
    what = "field"
  }, {
    address = "0x40",
    count = 32,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad10314",
    offset = 64,
    size = 32,
    what = "field"
  }, {
    address = "0x60",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 180,
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "WeaponHUDInterfaceStateAttachedTo",
            name = "stateAttachedTo",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6047",
            offset = 2,
            size = 2,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            metaName = "WeaponHUDInterfaceViewType",
            name = "allowedViewType",
            offset = 4,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6",
            is = "int",
            metaName = "HUDInterfaceChildAnchor",
            name = "anchor",
            offset = 6,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x8",
            count = 28,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6155",
            offset = 8,
            size = 28,
            what = "field"
          }, {
            address = "0x24",
            fields = { {
                address = "0x0",
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "x",
                        offset = 0,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "y",
                        offset = 2,
                        size = 2,
                        type = "short",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "VectorXYInt",
                    name = "anchorOffset",
                    offset = 0,
                    size = 4,
                    type = "VectorXYInt",
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "float",
                    name = "widthScale",
                    offset = 4,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "float",
                    name = "heightScale",
                    offset = 8,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0xc",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "dontScaleOffset",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "dontScaleSize",
                        offset = 1,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "useHighResScale",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceScalingFlags",
                    name = "scalingFlags",
                    offset = 12,
                    size = 2,
                    type = "HUDInterfaceScalingFlags",
                    what = "field"
                  }, {
                    address = "0xe",
                    count = 2,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5651",
                    offset = 14,
                    size = 2,
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 20,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5673",
                    offset = 16,
                    size = 20,
                    what = "field"
                  } },
                is = "struct",
                metaName = "HUDInterfaceElementPosition",
                name = "position",
                offset = 0,
                size = 36,
                type = "HUDInterfaceElementPosition",
                what = "field"
              }, {
                address = "0x24",
                fields = { {
                    address = "0x0",
                    is = "int",
                    metaName = "TagGroup",
                    name = "tagGroup",
                    offset = 0,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x4",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "path",
                    offset = 4,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "int",
                    name = "pathSize",
                    offset = 8,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0xc",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "value",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "index",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "id",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "field"
                      } },
                    is = "union",
                    metaName = "TableResourceHandle",
                    name = "tagHandle",
                    offset = 12,
                    size = 4,
                    type = "TableResourceHandle",
                    what = "field"
                  } },
                is = "struct",
                metaName = "TagReference",
                name = "interfaceBitmap",
                offset = 36,
                size = 16,
                type = "TagReference",
                what = "field"
              }, {
                address = "0x34",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "defaultColor",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "flashingColor",
                    offset = 4,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "float",
                    name = "flashPeriod",
                    offset = 8,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "float",
                    name = "flashDelay",
                    offset = 12,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x10",
                    is = "int",
                    name = "numberOfFlashes",
                    offset = 16,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x12",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "reverseDefaultFlashingColors",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceFlashFlags",
                    name = "flashFlags",
                    offset = 18,
                    size = 2,
                    type = "HUDInterfaceFlashFlags",
                    what = "field"
                  }, {
                    address = "0x14",
                    is = "float",
                    name = "flashLength",
                    offset = 20,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x18",
                    is = "int",
                    name = "disabledColor",
                    offset = 24,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  } },
                is = "struct",
                metaName = "HUDInterfaceElementColor",
                name = "color",
                offset = 52,
                size = 28,
                type = "HUDInterfaceElementColor",
                what = "field"
              }, {
                address = "0x50",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad7741",
                offset = 80,
                size = 4,
                what = "field"
              }, {
                address = "0x54",
                is = "int",
                name = "sequenceIndex",
                offset = 84,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x56",
                count = 2,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad7792",
                offset = 86,
                size = 2,
                what = "field"
              }, {
                address = "0x58",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "count",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x4",
                    count = 0,
                    elementSize = 480,
                    fields = { {
                        address = "0x0",
                        count = 2,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad8679",
                        offset = 0,
                        size = 2,
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "type",
                        offset = 2,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "int",
                        metaName = "FramebufferBlendFunction",
                        name = "framebufferBlendFunction",
                        offset = 4,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x6",
                        count = 2,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad8776",
                        offset = 6,
                        size = 2,
                        what = "field"
                      }, {
                        address = "0x8",
                        count = 32,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad8798",
                        offset = 8,
                        size = 32,
                        what = "field"
                      }, {
                        address = "0x28",
                        is = "int",
                        metaName = "HUDInterfaceMultitextureOverlayAnchor",
                        name = "primaryAnchor",
                        offset = 40,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x2a",
                        is = "int",
                        metaName = "HUDInterfaceMultitextureOverlayAnchor",
                        name = "secondaryAnchor",
                        offset = 42,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x2c",
                        is = "int",
                        metaName = "HUDInterfaceMultitextureOverlayAnchor",
                        name = "tertiaryAnchor",
                        offset = 44,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x2e",
                        is = "int",
                        metaName = "HUDInterfaceZeroToOneBlendFunction",
                        name = "zeroToOneBlendFunction",
                        offset = 46,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x30",
                        is = "int",
                        metaName = "HUDInterfaceZeroToOneBlendFunction",
                        name = "oneToTwoBlendFunction",
                        offset = 48,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x32",
                        count = 2,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad9131",
                        offset = 50,
                        size = 2,
                        what = "field"
                      }, {
                        address = "0x34",
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "x",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "float",
                            name = "y",
                            offset = 4,
                            size = 4,
                            type = "float",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXY",
                        name = "primaryScale",
                        offset = 52,
                        size = 8,
                        type = "VectorXY",
                        what = "field"
                      }, {
                        address = "0x3c",
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "x",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "float",
                            name = "y",
                            offset = 4,
                            size = 4,
                            type = "float",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXY",
                        name = "secondaryScale",
                        offset = 60,
                        size = 8,
                        type = "VectorXY",
                        what = "field"
                      }, {
                        address = "0x44",
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "x",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "float",
                            name = "y",
                            offset = 4,
                            size = 4,
                            type = "float",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXY",
                        name = "tertiaryScale",
                        offset = 68,
                        size = 8,
                        type = "VectorXY",
                        what = "field"
                      }, {
                        address = "0x4c",
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "x",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "float",
                            name = "y",
                            offset = 4,
                            size = 4,
                            type = "float",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXY",
                        name = "primaryOffset",
                        offset = 76,
                        size = 8,
                        type = "VectorXY",
                        what = "field"
                      }, {
                        address = "0x54",
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "x",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "float",
                            name = "y",
                            offset = 4,
                            size = 4,
                            type = "float",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXY",
                        name = "secondaryOffset",
                        offset = 84,
                        size = 8,
                        type = "VectorXY",
                        what = "field"
                      }, {
                        address = "0x5c",
                        fields = { {
                            address = "0x0",
                            is = "float",
                            name = "x",
                            offset = 0,
                            size = 4,
                            type = "float",
                            what = "field"
                          }, {
                            address = "0x4",
                            is = "float",
                            name = "y",
                            offset = 4,
                            size = 4,
                            type = "float",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXY",
                        name = "tertiaryOffset",
                        offset = 92,
                        size = 8,
                        type = "VectorXY",
                        what = "field"
                      }, {
                        address = "0x64",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            metaName = "TagGroup",
                            name = "tagGroup",
                            offset = 0,
                            size = 4,
                            type = "int",
                            what = "field"
                          }, {
                            address = "0x4",
                            count = 4,
                            elementSize = 1,
                            elementType = "char",
                            is = "ptr",
                            name = "path",
                            offset = 4,
                            size = 4,
                            what = "field"
                          }, {
                            address = "0x8",
                            is = "int",
                            name = "pathSize",
                            offset = 8,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0xc",
                            fields = { {
                                address = "0x0",
                                is = "int",
                                name = "value",
                                offset = 0,
                                size = 4,
                                type = "dword",
                                unsigned = true,
                                what = "field"
                              }, {
                                address = "0x0",
                                is = "int",
                                name = "index",
                                offset = 0,
                                size = 2,
                                type = "word",
                                unsigned = true,
                                what = "field"
                              }, {
                                address = "0x2",
                                is = "int",
                                name = "id",
                                offset = 2,
                                size = 2,
                                type = "word",
                                unsigned = true,
                                what = "field"
                              } },
                            is = "union",
                            metaName = "TableResourceHandle",
                            name = "tagHandle",
                            offset = 12,
                            size = 4,
                            type = "TableResourceHandle",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "TagReference",
                        name = "primary",
                        offset = 100,
                        size = 16,
                        type = "TagReference",
                        what = "field"
                      }, {
                        address = "0x74",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            metaName = "TagGroup",
                            name = "tagGroup",
                            offset = 0,
                            size = 4,
                            type = "int",
                            what = "field"
                          }, {
                            address = "0x4",
                            count = 4,
                            elementSize = 1,
                            elementType = "char",
                            is = "ptr",
                            name = "path",
                            offset = 4,
                            size = 4,
                            what = "field"
                          }, {
                            address = "0x8",
                            is = "int",
                            name = "pathSize",
                            offset = 8,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0xc",
                            fields = { {
                                address = "0x0",
                                is = "int",
                                name = "value",
                                offset = 0,
                                size = 4,
                                type = "dword",
                                unsigned = true,
                                what = "field"
                              }, {
                                address = "0x0",
                                is = "int",
                                name = "index",
                                offset = 0,
                                size = 2,
                                type = "word",
                                unsigned = true,
                                what = "field"
                              }, {
                                address = "0x2",
                                is = "int",
                                name = "id",
                                offset = 2,
                                size = 2,
                                type = "word",
                                unsigned = true,
                                what = "field"
                              } },
                            is = "union",
                            metaName = "TableResourceHandle",
                            name = "tagHandle",
                            offset = 12,
                            size = 4,
                            type = "TableResourceHandle",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "TagReference",
                        name = "secondary",
                        offset = 116,
                        size = 16,
                        type = "TagReference",
                        what = "field"
                      }, {
                        address = "0x84",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            metaName = "TagGroup",
                            name = "tagGroup",
                            offset = 0,
                            size = 4,
                            type = "int",
                            what = "field"
                          }, {
                            address = "0x4",
                            count = 4,
                            elementSize = 1,
                            elementType = "char",
                            is = "ptr",
                            name = "path",
                            offset = 4,
                            size = 4,
                            what = "field"
                          }, {
                            address = "0x8",
                            is = "int",
                            name = "pathSize",
                            offset = 8,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0xc",
                            fields = { {
                                address = "0x0",
                                is = "int",
                                name = "value",
                                offset = 0,
                                size = 4,
                                type = "dword",
                                unsigned = true,
                                what = "field"
                              }, {
                                address = "0x0",
                                is = "int",
                                name = "index",
                                offset = 0,
                                size = 2,
                                type = "word",
                                unsigned = true,
                                what = "field"
                              }, {
                                address = "0x2",
                                is = "int",
                                name = "id",
                                offset = 2,
                                size = 2,
                                type = "word",
                                unsigned = true,
                                what = "field"
                              } },
                            is = "union",
                            metaName = "TableResourceHandle",
                            name = "tagHandle",
                            offset = 12,
                            size = 4,
                            type = "TableResourceHandle",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "TagReference",
                        name = "tertiary",
                        offset = 132,
                        size = 16,
                        type = "TagReference",
                        what = "field"
                      }, {
                        address = "0x94",
                        is = "int",
                        metaName = "HUDInterfaceWrapMode",
                        name = "primaryWrapMode",
                        offset = 148,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x96",
                        is = "int",
                        metaName = "HUDInterfaceWrapMode",
                        name = "secondaryWrapMode",
                        offset = 150,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x98",
                        is = "int",
                        metaName = "HUDInterfaceWrapMode",
                        name = "tertiaryWrapMode",
                        offset = 152,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x9a",
                        count = 2,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad9546",
                        offset = 154,
                        size = 2,
                        what = "field"
                      }, {
                        address = "0x9c",
                        count = 184,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad9568",
                        offset = 156,
                        size = 184,
                        what = "field"
                      }, {
                        address = "0x154",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "count",
                            offset = 0,
                            size = 4,
                            type = "dword",
                            unsigned = true,
                            what = "field"
                          }, {
                            address = "0x4",
                            count = 0,
                            elementSize = 220,
                            fields = { {
                                address = "0x0",
                                count = 64,
                                elementSize = 1,
                                elementType = "char",
                                is = "array",
                                name = "pad8118",
                                offset = 0,
                                size = 64,
                                what = "field"
                              }, {
                                address = "0x40",
                                is = "int",
                                metaName = "HUDInterfaceDestinationType",
                                name = "destinationType",
                                offset = 64,
                                size = 2,
                                type = "short",
                                what = "field"
                              }, {
                                address = "0x42",
                                is = "int",
                                metaName = "HUDInterfaceDestination",
                                name = "destination",
                                offset = 66,
                                size = 2,
                                type = "short",
                                what = "field"
                              }, {
                                address = "0x44",
                                is = "int",
                                metaName = "HUDInterfaceSource",
                                name = "source",
                                offset = 68,
                                size = 2,
                                type = "short",
                                what = "field"
                              }, {
                                address = "0x46",
                                count = 2,
                                elementSize = 1,
                                elementType = "char",
                                is = "array",
                                name = "pad8263",
                                offset = 70,
                                size = 2,
                                what = "field"
                              }, {
                                address = "0x48",
                                count = 2,
                                elementSize = 4,
                                elementType = "float",
                                is = "array",
                                name = "inBounds",
                                offset = 72,
                                size = 8,
                                what = "field"
                              }, {
                                address = "0x50",
                                count = 2,
                                elementSize = 4,
                                elementType = "float",
                                is = "array",
                                name = "outBounds",
                                offset = 80,
                                size = 8,
                                what = "field"
                              }, {
                                address = "0x58",
                                count = 64,
                                elementSize = 1,
                                elementType = "char",
                                is = "array",
                                name = "pad8334",
                                offset = 88,
                                size = 64,
                                what = "field"
                              }, {
                                address = "0x98",
                                count = 2,
                                elementSize = 12,
                                fields = { {
                                    address = "0x0",
                                    is = "float",
                                    name = "r",
                                    offset = 0,
                                    size = 4,
                                    type = "float",
                                    what = "field"
                                  }, {
                                    address = "0x4",
                                    is = "float",
                                    name = "g",
                                    offset = 4,
                                    size = 4,
                                    type = "float",
                                    what = "field"
                                  }, {
                                    address = "0x8",
                                    is = "float",
                                    name = "b",
                                    offset = 8,
                                    size = 4,
                                    type = "float",
                                    what = "field"
                                  } },
                                is = "array",
                                name = "tint",
                                offset = 152,
                                size = 24,
                                what = "field"
                              }, {
                                address = "0xb0",
                                is = "int",
                                metaName = "WaveFunction",
                                name = "periodicFunction",
                                offset = 176,
                                size = 2,
                                type = "short",
                                what = "field"
                              }, {
                                address = "0xb2",
                                count = 2,
                                elementSize = 1,
                                elementType = "char",
                                is = "array",
                                name = "pad8415",
                                offset = 178,
                                size = 2,
                                what = "field"
                              }, {
                                address = "0xb4",
                                is = "float",
                                name = "functionPeriod",
                                offset = 180,
                                size = 4,
                                type = "float",
                                what = "field"
                              }, {
                                address = "0xb8",
                                is = "float",
                                name = "functionPhase",
                                offset = 184,
                                size = 4,
                                type = "float",
                                what = "field"
                              }, {
                                address = "0xbc",
                                count = 32,
                                elementSize = 1,
                                elementType = "char",
                                is = "array",
                                name = "pad8490",
                                offset = 188,
                                size = 32,
                                what = "field"
                              } },
                            is = "ptr",
                            name = "elements",
                            offset = 4,
                            size = 4,
                            what = "field"
                          }, {
                            address = "0x8",
                            count = 0,
                            elementSize = 20,
                            fields = { {
                                address = "0x0",
                                count = 4,
                                elementSize = 1,
                                elementType = "char",
                                is = "ptr",
                                name = "name",
                                offset = 0,
                                size = 4,
                                what = "field"
                              }, {
                                address = "0x4",
                                is = "int",
                                name = "maximum",
                                offset = 4,
                                size = 4,
                                type = "int",
                                what = "field"
                              }, {
                                address = "0x8",
                                count = 4,
                                elementSize = 1,
                                elementType = "char",
                                is = "array",
                                name = "padding",
                                offset = 8,
                                size = 4,
                                what = "field"
                              }, {
                                address = "0xc",
                                is = "int",
                                name = "elementsSize",
                                offset = 12,
                                size = 4,
                                type = "int",
                                what = "field"
                              }, {
                                address = "0x10",
                                count = 0,
                                elementSize = "none",
                                elementType = "void",
                                is = "ptr",
                                name = "fields",
                                offset = 16,
                                size = 4,
                                what = "field"
                              } },
                            is = "ptr",
                            name = "definition",
                            offset = 8,
                            size = 4,
                            what = "field"
                          } },
                        is = "struct",
                        name = "effectors",
                        offset = 340,
                        size = 12,
                        what = "field"
                      }, {
                        address = "0x160",
                        count = 128,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad9724",
                        offset = 352,
                        size = 128,
                        what = "field"
                      } },
                    is = "ptr",
                    name = "elements",
                    offset = 4,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 0,
                    elementSize = 20,
                    fields = { {
                        address = "0x0",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "ptr",
                        name = "name",
                        offset = 0,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "int",
                        name = "maximum",
                        offset = 4,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x8",
                        count = 4,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "padding",
                        offset = 8,
                        size = 4,
                        what = "field"
                      }, {
                        address = "0xc",
                        is = "int",
                        name = "elementsSize",
                        offset = 12,
                        size = 4,
                        type = "int",
                        what = "field"
                      }, {
                        address = "0x10",
                        count = 0,
                        elementSize = "none",
                        elementType = "void",
                        is = "ptr",
                        name = "fields",
                        offset = 16,
                        size = 4,
                        what = "field"
                      } },
                    is = "ptr",
                    name = "definition",
                    offset = 8,
                    size = 4,
                    what = "field"
                  } },
                is = "struct",
                name = "multitextureOverlays",
                offset = 88,
                size = 12,
                what = "field"
              }, {
                address = "0x64",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad7950",
                offset = 100,
                size = 4,
                what = "field"
              } },
            is = "struct",
            metaName = "HUDInterfaceStaticElement",
            name = "properties",
            offset = 36,
            size = 104,
            type = "HUDInterfaceStaticElement",
            what = "field"
          }, {
            address = "0x8c",
            count = 40,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6220",
            offset = 140,
            size = 40,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "staticElements",
    offset = 96,
    size = 12,
    what = "field"
  }, {
    address = "0x6c",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 180,
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "WeaponHUDInterfaceStateAttachedTo",
            name = "stateAttachedTo",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6442",
            offset = 2,
            size = 2,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            metaName = "WeaponHUDInterfaceViewType",
            name = "allowedViewType",
            offset = 4,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6",
            is = "int",
            metaName = "HUDInterfaceChildAnchor",
            name = "anchor",
            offset = 6,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x8",
            count = 28,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6550",
            offset = 8,
            size = 28,
            what = "field"
          }, {
            address = "0x24",
            fields = { {
                address = "0x0",
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "x",
                        offset = 0,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "y",
                        offset = 2,
                        size = 2,
                        type = "short",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "VectorXYInt",
                    name = "anchorOffset",
                    offset = 0,
                    size = 4,
                    type = "VectorXYInt",
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "float",
                    name = "widthScale",
                    offset = 4,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "float",
                    name = "heightScale",
                    offset = 8,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0xc",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "dontScaleOffset",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "dontScaleSize",
                        offset = 1,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "useHighResScale",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceScalingFlags",
                    name = "scalingFlags",
                    offset = 12,
                    size = 2,
                    type = "HUDInterfaceScalingFlags",
                    what = "field"
                  }, {
                    address = "0xe",
                    count = 2,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5651",
                    offset = 14,
                    size = 2,
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 20,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5673",
                    offset = 16,
                    size = 20,
                    what = "field"
                  } },
                is = "struct",
                metaName = "HUDInterfaceElementPosition",
                name = "position",
                offset = 0,
                size = 36,
                type = "HUDInterfaceElementPosition",
                what = "field"
              }, {
                address = "0x24",
                fields = { {
                    address = "0x0",
                    is = "int",
                    metaName = "TagGroup",
                    name = "tagGroup",
                    offset = 0,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x4",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "path",
                    offset = 4,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "int",
                    name = "pathSize",
                    offset = 8,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0xc",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "value",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "index",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "id",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "field"
                      } },
                    is = "union",
                    metaName = "TableResourceHandle",
                    name = "tagHandle",
                    offset = 12,
                    size = 4,
                    type = "TableResourceHandle",
                    what = "field"
                  } },
                is = "struct",
                metaName = "TagReference",
                name = "meterBitmap",
                offset = 36,
                size = 16,
                type = "TagReference",
                what = "field"
              }, {
                address = "0x34",
                is = "int",
                name = "colorAtMeterMinimum",
                offset = 52,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x38",
                is = "int",
                name = "colorAtMeterMaximum",
                offset = 56,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x3c",
                is = "int",
                name = "flashColor",
                offset = 60,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x40",
                is = "int",
                name = "emptyColor",
                offset = 64,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x44",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "useMinMaxForStateChanges",
                    offset = 0,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "interpolateBetweenMinMaxFlashColorsAsStateChanges",
                    offset = 1,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "interpolateColorAlongHsvSpace",
                    offset = 2,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "moreColorsForHsvInterpolation",
                    offset = 3,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "invertInterpolation",
                    offset = 4,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "useXboxShading",
                    offset = 5,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  } },
                is = "struct",
                metaName = "HUDInterfaceMeterFlags",
                name = "flags",
                offset = 68,
                size = 1,
                type = "HUDInterfaceMeterFlags",
                what = "field"
              }, {
                address = "0x45",
                is = "int",
                name = "minimumMeterValue",
                offset = 69,
                size = 1,
                type = "char",
                what = "field"
              }, {
                address = "0x46",
                is = "int",
                name = "sequenceIndex",
                offset = 70,
                size = 2,
                type = "word",
                unsigned = true,
                what = "field"
              }, {
                address = "0x48",
                is = "int",
                name = "alphaMultiplier",
                offset = 72,
                size = 1,
                type = "char",
                what = "field"
              }, {
                address = "0x49",
                is = "int",
                name = "alphaBias",
                offset = 73,
                size = 1,
                type = "char",
                what = "field"
              }, {
                address = "0x4a",
                is = "int",
                name = "valueScale",
                offset = 74,
                size = 2,
                type = "short",
                what = "field"
              }, {
                address = "0x4c",
                is = "float",
                name = "opacity",
                offset = 76,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x50",
                is = "float",
                name = "translucency",
                offset = 80,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x54",
                is = "int",
                name = "disabledColor",
                offset = 84,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x58",
                is = "float",
                name = "minAlpha",
                offset = 88,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x5c",
                count = 12,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad6314",
                offset = 92,
                size = 12,
                what = "field"
              } },
            is = "struct",
            metaName = "HUDInterfaceMeterElement",
            name = "properties",
            offset = 36,
            size = 104,
            type = "HUDInterfaceMeterElement",
            what = "field"
          }, {
            address = "0x8c",
            count = 40,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6614",
            offset = 140,
            size = 40,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "meterElements",
    offset = 108,
    size = 12,
    what = "field"
  }, {
    address = "0x78",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 160,
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "WeaponHUDInterfaceStateAttachedTo",
            name = "stateAttachedTo",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6821",
            offset = 2,
            size = 2,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            metaName = "WeaponHUDInterfaceViewType",
            name = "allowedViewType",
            offset = 4,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6",
            is = "int",
            metaName = "HUDInterfaceChildAnchor",
            name = "anchor",
            offset = 6,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x8",
            count = 28,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad6929",
            offset = 8,
            size = 28,
            what = "field"
          }, {
            address = "0x24",
            fields = { {
                address = "0x0",
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "x",
                        offset = 0,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x2",
                        is = "int",
                        name = "y",
                        offset = 2,
                        size = 2,
                        type = "short",
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "VectorXYInt",
                    name = "anchorOffset",
                    offset = 0,
                    size = 4,
                    type = "VectorXYInt",
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "float",
                    name = "widthScale",
                    offset = 4,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "float",
                    name = "heightScale",
                    offset = 8,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0xc",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "dontScaleOffset",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "dontScaleSize",
                        offset = 1,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "useHighResScale",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceScalingFlags",
                    name = "scalingFlags",
                    offset = 12,
                    size = 2,
                    type = "HUDInterfaceScalingFlags",
                    what = "field"
                  }, {
                    address = "0xe",
                    count = 2,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5651",
                    offset = 14,
                    size = 2,
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 20,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad5673",
                    offset = 16,
                    size = 20,
                    what = "field"
                  } },
                is = "struct",
                metaName = "HUDInterfaceElementPosition",
                name = "position",
                offset = 0,
                size = 36,
                type = "HUDInterfaceElementPosition",
                what = "field"
              }, {
                address = "0x24",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "defaultColor",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "flashingColor",
                    offset = 4,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x8",
                    is = "float",
                    name = "flashPeriod",
                    offset = 8,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "float",
                    name = "flashDelay",
                    offset = 12,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x10",
                    is = "int",
                    name = "numberOfFlashes",
                    offset = 16,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x12",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "reverseDefaultFlashingColors",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceFlashFlags",
                    name = "flashFlags",
                    offset = 18,
                    size = 2,
                    type = "HUDInterfaceFlashFlags",
                    what = "field"
                  }, {
                    address = "0x14",
                    is = "float",
                    name = "flashLength",
                    offset = 20,
                    size = 4,
                    type = "float",
                    what = "field"
                  }, {
                    address = "0x18",
                    is = "int",
                    name = "disabledColor",
                    offset = 24,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  } },
                is = "struct",
                metaName = "HUDInterfaceElementColor",
                name = "color",
                offset = 36,
                size = 28,
                type = "HUDInterfaceElementColor",
                what = "field"
              }, {
                address = "0x40",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad6913",
                offset = 64,
                size = 4,
                what = "field"
              }, {
                address = "0x44",
                is = "int",
                name = "maximumNumberOfDigits",
                offset = 68,
                size = 1,
                type = "char",
                what = "field"
              }, {
                address = "0x45",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "showLeadingZeros",
                    offset = 0,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "onlyShowWhenZoomed",
                    offset = 1,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "drawATrailingM",
                    offset = 2,
                    size = 1,
                    type = "byte",
                    unsigned = true,
                    what = "bitfield"
                  } },
                is = "struct",
                metaName = "HUDInterfaceNumberFlags",
                name = "flags",
                offset = 69,
                size = 1,
                type = "HUDInterfaceNumberFlags",
                what = "field"
              }, {
                address = "0x46",
                is = "int",
                name = "numberOfFractionalDigits",
                offset = 70,
                size = 1,
                type = "char",
                what = "field"
              }, {
                address = "0x47",
                count = 1,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad7047",
                offset = 71,
                size = 1,
                what = "field"
              }, {
                address = "0x48",
                count = 12,
                elementSize = 1,
                elementType = "char",
                is = "array",
                name = "pad7069",
                offset = 72,
                size = 12,
                what = "field"
              } },
            is = "struct",
            metaName = "HUDInterfaceNumberElement",
            name = "properties",
            offset = 36,
            size = 84,
            type = "HUDInterfaceNumberElement",
            what = "field"
          }, {
            address = "0x78",
            fields = { {
                address = "0x0",
                is = "int",
                name = "divideNumberByClipSize",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponHUDInterfaceNumberWeaponSpecificFlags",
            name = "weaponSpecificFlags",
            offset = 120,
            size = 2,
            type = "WeaponHUDInterfaceNumberWeaponSpecificFlags",
            what = "field"
          }, {
            address = "0x7a",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7065",
            offset = 122,
            size = 2,
            what = "field"
          }, {
            address = "0x7c",
            count = 36,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7087",
            offset = 124,
            size = 36,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "numberElements",
    offset = 120,
    size = 12,
    what = "field"
  }, {
    address = "0x84",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 104,
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "WeaponHUDInterfaceCrosshairType",
            name = "crosshairType",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7680",
            offset = 2,
            size = 2,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            metaName = "WeaponHUDInterfaceViewType",
            name = "allowedViewType",
            offset = 4,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7752",
            offset = 6,
            size = 2,
            what = "field"
          }, {
            address = "0x8",
            count = 28,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7774",
            offset = 8,
            size = 28,
            what = "field"
          }, {
            address = "0x24",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "crosshairBitmap",
            offset = 36,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x34",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 108,
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "x",
                            offset = 0,
                            size = 2,
                            type = "short",
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "y",
                            offset = 2,
                            size = 2,
                            type = "short",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXYInt",
                        name = "anchorOffset",
                        offset = 0,
                        size = 4,
                        type = "VectorXYInt",
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "float",
                        name = "widthScale",
                        offset = 4,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "float",
                        name = "heightScale",
                        offset = 8,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "dontScaleOffset",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "dontScaleSize",
                            offset = 1,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "useHighResScale",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          } },
                        is = "struct",
                        metaName = "HUDInterfaceScalingFlags",
                        name = "scalingFlags",
                        offset = 12,
                        size = 2,
                        type = "HUDInterfaceScalingFlags",
                        what = "field"
                      }, {
                        address = "0xe",
                        count = 2,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad5651",
                        offset = 14,
                        size = 2,
                        what = "field"
                      }, {
                        address = "0x10",
                        count = 20,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad5673",
                        offset = 16,
                        size = 20,
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceElementPosition",
                    name = "position",
                    offset = 0,
                    size = 36,
                    type = "HUDInterfaceElementPosition",
                    what = "field"
                  }, {
                    address = "0x24",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "defaultColor",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "int",
                        name = "flashingColor",
                        offset = 4,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "float",
                        name = "flashPeriod",
                        offset = 8,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0xc",
                        is = "float",
                        name = "flashDelay",
                        offset = 12,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x10",
                        is = "int",
                        name = "numberOfFlashes",
                        offset = 16,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x12",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "reverseDefaultFlashingColors",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          } },
                        is = "struct",
                        metaName = "HUDInterfaceFlashFlags",
                        name = "flashFlags",
                        offset = 18,
                        size = 2,
                        type = "HUDInterfaceFlashFlags",
                        what = "field"
                      }, {
                        address = "0x14",
                        is = "float",
                        name = "flashLength",
                        offset = 20,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x18",
                        is = "int",
                        name = "disabledColor",
                        offset = 24,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceElementColor",
                    name = "color",
                    offset = 36,
                    size = 28,
                    type = "HUDInterfaceElementColor",
                    what = "field"
                  }, {
                    address = "0x40",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad7327",
                    offset = 64,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x44",
                    is = "int",
                    name = "frameRate",
                    offset = 68,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x46",
                    is = "int",
                    name = "sequenceIndex",
                    offset = 70,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x48",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "flashesWhenActive",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "notASprite",
                        offset = 1,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "showOnlyWhenZoomed",
                        offset = 2,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "showSniperData",
                        offset = 3,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "hideAreaOutsideReticle",
                        offset = 4,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "oneZoomLevel",
                        offset = 5,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "dontShowWhenZoomed",
                        offset = 6,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "WeaponHUDInterfaceCrosshairOverlayFlags",
                    name = "flags",
                    offset = 72,
                    size = 4,
                    type = "WeaponHUDInterfaceCrosshairOverlayFlags",
                    what = "field"
                  }, {
                    address = "0x4c",
                    count = 32,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad7453",
                    offset = 76,
                    size = 32,
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "crosshairOverlays",
            offset = 52,
            size = 12,
            what = "field"
          }, {
            address = "0x40",
            count = 40,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad7968",
            offset = 64,
            size = 40,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "crosshairs",
    offset = 132,
    size = 12,
    what = "field"
  }, {
    address = "0x90",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 104,
        fields = { {
            address = "0x0",
            is = "int",
            metaName = "WeaponHUDInterfaceStateAttachedTo",
            name = "stateAttachedTo",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad8625",
            offset = 2,
            size = 2,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            metaName = "WeaponHUDInterfaceViewType",
            name = "allowedViewType",
            offset = 4,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x6",
            is = "int",
            metaName = "HUDInterfaceChildAnchor",
            name = "anchor",
            offset = 6,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x8",
            count = 28,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad8733",
            offset = 8,
            size = 28,
            what = "field"
          }, {
            address = "0x24",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "overlayBitmap",
            offset = 36,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x34",
            fields = { {
                address = "0x0",
                is = "int",
                name = "count",
                offset = 0,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0x4",
                count = 0,
                elementSize = 136,
                fields = { {
                    address = "0x0",
                    fields = { {
                        address = "0x0",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "x",
                            offset = 0,
                            size = 2,
                            type = "short",
                            what = "field"
                          }, {
                            address = "0x2",
                            is = "int",
                            name = "y",
                            offset = 2,
                            size = 2,
                            type = "short",
                            what = "field"
                          } },
                        is = "struct",
                        metaName = "VectorXYInt",
                        name = "anchorOffset",
                        offset = 0,
                        size = 4,
                        type = "VectorXYInt",
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "float",
                        name = "widthScale",
                        offset = 4,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "float",
                        name = "heightScale",
                        offset = 8,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0xc",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "dontScaleOffset",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "dontScaleSize",
                            offset = 1,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          }, {
                            address = "0x0",
                            is = "int",
                            name = "useHighResScale",
                            offset = 2,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          } },
                        is = "struct",
                        metaName = "HUDInterfaceScalingFlags",
                        name = "scalingFlags",
                        offset = 12,
                        size = 2,
                        type = "HUDInterfaceScalingFlags",
                        what = "field"
                      }, {
                        address = "0xe",
                        count = 2,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad5651",
                        offset = 14,
                        size = 2,
                        what = "field"
                      }, {
                        address = "0x10",
                        count = 20,
                        elementSize = 1,
                        elementType = "char",
                        is = "array",
                        name = "pad5673",
                        offset = 16,
                        size = 20,
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceElementPosition",
                    name = "position",
                    offset = 0,
                    size = 36,
                    type = "HUDInterfaceElementPosition",
                    what = "field"
                  }, {
                    address = "0x24",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "defaultColor",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x4",
                        is = "int",
                        name = "flashingColor",
                        offset = 4,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      }, {
                        address = "0x8",
                        is = "float",
                        name = "flashPeriod",
                        offset = 8,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0xc",
                        is = "float",
                        name = "flashDelay",
                        offset = 12,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x10",
                        is = "int",
                        name = "numberOfFlashes",
                        offset = 16,
                        size = 2,
                        type = "short",
                        what = "field"
                      }, {
                        address = "0x12",
                        fields = { {
                            address = "0x0",
                            is = "int",
                            name = "reverseDefaultFlashingColors",
                            offset = 0,
                            size = 2,
                            type = "word",
                            unsigned = true,
                            what = "bitfield"
                          } },
                        is = "struct",
                        metaName = "HUDInterfaceFlashFlags",
                        name = "flashFlags",
                        offset = 18,
                        size = 2,
                        type = "HUDInterfaceFlashFlags",
                        what = "field"
                      }, {
                        address = "0x14",
                        is = "float",
                        name = "flashLength",
                        offset = 20,
                        size = 4,
                        type = "float",
                        what = "field"
                      }, {
                        address = "0x18",
                        is = "int",
                        name = "disabledColor",
                        offset = 24,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "field"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceElementColor",
                    name = "color",
                    offset = 36,
                    size = 28,
                    type = "HUDInterfaceElementColor",
                    what = "field"
                  }, {
                    address = "0x40",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad8205",
                    offset = 64,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x44",
                    is = "int",
                    name = "frameRate",
                    offset = 68,
                    size = 2,
                    type = "short",
                    what = "field"
                  }, {
                    address = "0x46",
                    count = 2,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad8251",
                    offset = 70,
                    size = 2,
                    what = "field"
                  }, {
                    address = "0x48",
                    is = "int",
                    name = "sequenceIndex",
                    offset = 72,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x4a",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "showOnFlashing",
                        offset = 0,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "showOnEmpty",
                        offset = 1,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "showOnReloadOverheating",
                        offset = 2,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "showOnDefault",
                        offset = 3,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      }, {
                        address = "0x0",
                        is = "int",
                        name = "showAlways",
                        offset = 4,
                        size = 2,
                        type = "word",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "WeaponHUDInterfaceOverlayType",
                    name = "type",
                    offset = 74,
                    size = 2,
                    type = "WeaponHUDInterfaceOverlayType",
                    what = "field"
                  }, {
                    address = "0x4c",
                    fields = { {
                        address = "0x0",
                        is = "int",
                        name = "flashesWhenActive",
                        offset = 0,
                        size = 4,
                        type = "dword",
                        unsigned = true,
                        what = "bitfield"
                      } },
                    is = "struct",
                    metaName = "HUDInterfaceOverlayFlashFlags",
                    name = "flags",
                    offset = 76,
                    size = 4,
                    type = "HUDInterfaceOverlayFlashFlags",
                    what = "field"
                  }, {
                    address = "0x50",
                    count = 16,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad8383",
                    offset = 80,
                    size = 16,
                    what = "field"
                  }, {
                    address = "0x60",
                    count = 40,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "pad8406",
                    offset = 96,
                    size = 40,
                    what = "field"
                  } },
                is = "ptr",
                name = "elements",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                count = 0,
                elementSize = 20,
                fields = { {
                    address = "0x0",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "ptr",
                    name = "name",
                    offset = 0,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0x4",
                    is = "int",
                    name = "maximum",
                    offset = 4,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x8",
                    count = 4,
                    elementSize = 1,
                    elementType = "char",
                    is = "array",
                    name = "padding",
                    offset = 8,
                    size = 4,
                    what = "field"
                  }, {
                    address = "0xc",
                    is = "int",
                    name = "elementsSize",
                    offset = 12,
                    size = 4,
                    type = "int",
                    what = "field"
                  }, {
                    address = "0x10",
                    count = 0,
                    elementSize = "none",
                    elementType = "void",
                    is = "ptr",
                    name = "fields",
                    offset = 16,
                    size = 4,
                    what = "field"
                  } },
                is = "ptr",
                name = "definition",
                offset = 8,
                size = 4,
                what = "field"
              } },
            is = "struct",
            name = "overlays",
            offset = 52,
            size = 12,
            what = "field"
          }, {
            address = "0x40",
            count = 40,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad8906",
            offset = 64,
            size = 40,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "overlayElements",
    offset = 144,
    size = 12,
    what = "field"
  }, {
    address = "0x9c",
    fields = { {
        address = "0x0",
        is = "int",
        name = "aim",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "zoomOverlay",
        offset = 1,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "charge",
        offset = 2,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "shouldReload",
        offset = 3,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "flashHeat",
        offset = 4,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "flashTotalAmmo",
        offset = 5,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "flashBattery",
        offset = 6,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x0",
        is = "int",
        name = "reloadOverheat",
        offset = 7,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "flashWhenFiringAndNoAmmo",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "flashWhenThrowingAndNoGrenade",
        offset = 9,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "lowAmmoAndNoneLeftToReload",
        offset = 10,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "shouldReloadSecondaryTrigger",
        offset = 11,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "flashSecondaryTotalAmmo",
        offset = 12,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "flashSecondaryReload",
        offset = 13,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "flashWhenFiringSecondaryTriggerWithNoAmmo",
        offset = 14,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x1",
        is = "int",
        name = "lowSecondaryAmmoAndNoneLeftToReload",
        offset = 15,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x2",
        is = "int",
        name = "primaryTriggerReady",
        offset = 16,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x2",
        is = "int",
        name = "secondaryTriggerReady",
        offset = 17,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      }, {
        address = "0x2",
        is = "int",
        name = "flashWhenFiringWithDepletedBattery",
        offset = 18,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "bitfield"
      } },
    is = "struct",
    metaName = "WeaponHUDInterfaceCrosshairTypeFlags",
    name = "crosshairTypes",
    offset = 156,
    size = 4,
    type = "WeaponHUDInterfaceCrosshairTypeFlags",
    what = "field"
  }, {
    address = "0xa0",
    count = 12,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad11023",
    offset = 160,
    size = 12,
    what = "field"
  }, {
    address = "0xac",
    fields = { {
        address = "0x0",
        is = "int",
        name = "count",
        offset = 0,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0x4",
        count = 0,
        elementSize = 184,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9080",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            fields = { {
                address = "0x0",
                is = "int",
                name = "onlyWhenZoomed",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponHUDInterfaceScreenEffectDefinitionMaskFlags",
            name = "maskFlags",
            offset = 4,
            size = 2,
            type = "WeaponHUDInterfaceScreenEffectDefinitionMaskFlags",
            what = "field"
          }, {
            address = "0x6",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9168",
            offset = 6,
            size = 2,
            what = "field"
          }, {
            address = "0x8",
            count = 16,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9190",
            offset = 8,
            size = 16,
            what = "field"
          }, {
            address = "0x18",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "maskFullscreen",
            offset = 24,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x28",
            fields = { {
                address = "0x0",
                is = "int",
                metaName = "TagGroup",
                name = "tagGroup",
                offset = 0,
                size = 4,
                type = "int",
                what = "field"
              }, {
                address = "0x4",
                count = 4,
                elementSize = 1,
                elementType = "char",
                is = "ptr",
                name = "path",
                offset = 4,
                size = 4,
                what = "field"
              }, {
                address = "0x8",
                is = "int",
                name = "pathSize",
                offset = 8,
                size = 4,
                type = "dword",
                unsigned = true,
                what = "field"
              }, {
                address = "0xc",
                fields = { {
                    address = "0x0",
                    is = "int",
                    name = "value",
                    offset = 0,
                    size = 4,
                    type = "dword",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x0",
                    is = "int",
                    name = "index",
                    offset = 0,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  }, {
                    address = "0x2",
                    is = "int",
                    name = "id",
                    offset = 2,
                    size = 2,
                    type = "word",
                    unsigned = true,
                    what = "field"
                  } },
                is = "union",
                metaName = "TableResourceHandle",
                name = "tagHandle",
                offset = 12,
                size = 4,
                type = "TableResourceHandle",
                what = "field"
              } },
            is = "struct",
            metaName = "TagReference",
            name = "maskSplitscreen",
            offset = 40,
            size = 16,
            type = "TagReference",
            what = "field"
          }, {
            address = "0x38",
            count = 8,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9282",
            offset = 56,
            size = 8,
            what = "field"
          }, {
            address = "0x40",
            fields = { {
                address = "0x0",
                is = "int",
                name = "onlyWhenZoomed",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponHUDInterfaceScreenEffectDefinitionMaskFlags",
            name = "convolutionFlags",
            offset = 64,
            size = 2,
            type = "WeaponHUDInterfaceScreenEffectDefinitionMaskFlags",
            what = "field"
          }, {
            address = "0x42",
            count = 2,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9377",
            offset = 66,
            size = 2,
            what = "field"
          }, {
            address = "0x44",
            count = 2,
            elementSize = 4,
            elementType = "float",
            is = "array",
            name = "convolutionFovInBounds",
            offset = 68,
            size = 8,
            what = "field"
          }, {
            address = "0x4c",
            count = 2,
            elementSize = 4,
            elementType = "float",
            is = "array",
            name = "convolutionRadiusOutBounds",
            offset = 76,
            size = 8,
            what = "field"
          }, {
            address = "0x54",
            count = 24,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9483",
            offset = 84,
            size = 24,
            what = "field"
          }, {
            address = "0x6c",
            fields = { {
                address = "0x0",
                is = "int",
                name = "onlyWhenZoomed",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "connectToFlashlight",
                offset = 1,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "masked",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponHUDInterfaceScreenEffectDefinitionNightVisionFlags",
            name = "evenMoreFlags",
            offset = 108,
            size = 2,
            type = "WeaponHUDInterfaceScreenEffectDefinitionNightVisionFlags",
            what = "field"
          }, {
            address = "0x6e",
            is = "int",
            name = "nightVisionScriptSource",
            offset = 110,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x70",
            is = "float",
            name = "nightVisionIntensity",
            offset = 112,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x74",
            count = 24,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9658",
            offset = 116,
            size = 24,
            what = "field"
          }, {
            address = "0x8c",
            fields = { {
                address = "0x0",
                is = "int",
                name = "onlyWhenZoomed",
                offset = 0,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "connectToFlashlight",
                offset = 1,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "additive",
                offset = 2,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              }, {
                address = "0x0",
                is = "int",
                name = "masked",
                offset = 3,
                size = 2,
                type = "word",
                unsigned = true,
                what = "bitfield"
              } },
            is = "struct",
            metaName = "WeaponHUDInterfaceScreenEffectDefinitionDesaturationFlags",
            name = "desaturationFlags",
            offset = 140,
            size = 2,
            type = "WeaponHUDInterfaceScreenEffectDefinitionDesaturationFlags",
            what = "field"
          }, {
            address = "0x8e",
            is = "int",
            name = "desaturationScriptSource",
            offset = 142,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x90",
            is = "float",
            name = "desaturationIntensity",
            offset = 144,
            size = 4,
            type = "float",
            what = "field"
          }, {
            address = "0x94",
            fields = { {
                address = "0x0",
                is = "float",
                name = "r",
                offset = 0,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x4",
                is = "float",
                name = "g",
                offset = 4,
                size = 4,
                type = "float",
                what = "field"
              }, {
                address = "0x8",
                is = "float",
                name = "b",
                offset = 8,
                size = 4,
                type = "float",
                what = "field"
              } },
            is = "struct",
            metaName = "ColorRGB",
            name = "effectTint",
            offset = 148,
            size = 12,
            type = "ColorRGB",
            what = "field"
          }, {
            address = "0xa0",
            count = 24,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "pad9863",
            offset = 160,
            size = 24,
            what = "field"
          } },
        is = "ptr",
        name = "elements",
        offset = 4,
        size = 4,
        what = "field"
      }, {
        address = "0x8",
        count = 0,
        elementSize = 20,
        fields = { {
            address = "0x0",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "ptr",
            name = "name",
            offset = 0,
            size = 4,
            what = "field"
          }, {
            address = "0x4",
            is = "int",
            name = "maximum",
            offset = 4,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x8",
            count = 4,
            elementSize = 1,
            elementType = "char",
            is = "array",
            name = "padding",
            offset = 8,
            size = 4,
            what = "field"
          }, {
            address = "0xc",
            is = "int",
            name = "elementsSize",
            offset = 12,
            size = 4,
            type = "int",
            what = "field"
          }, {
            address = "0x10",
            count = 0,
            elementSize = "none",
            elementType = "void",
            is = "ptr",
            name = "fields",
            offset = 16,
            size = 4,
            what = "field"
          } },
        is = "ptr",
        name = "definition",
        offset = 8,
        size = 4,
        what = "field"
      } },
    is = "struct",
    name = "screenEffect",
    offset = 172,
    size = 12,
    what = "field"
  }, {
    address = "0xb8",
    count = 132,
    elementSize = 1,
    elementType = "char",
    is = "array",
    name = "pad11174",
    offset = 184,
    size = 132,
    what = "field"
  }, {
    address = "0x13c",
    fields = { {
        address = "0x0",
        is = "int",
        name = "sequenceIndex",
        offset = 0,
        size = 2,
        type = "word",
        unsigned = true,
        what = "field"
      }, {
        address = "0x2",
        is = "int",
        name = "widthOffset",
        offset = 2,
        size = 2,
        type = "short",
        what = "field"
      }, {
        address = "0x4",
        fields = { {
            address = "0x0",
            is = "int",
            name = "x",
            offset = 0,
            size = 2,
            type = "short",
            what = "field"
          }, {
            address = "0x2",
            is = "int",
            name = "y",
            offset = 2,
            size = 2,
            type = "short",
            what = "field"
          } },
        is = "struct",
        metaName = "VectorXYInt",
        name = "offsetFromReferenceCorner",
        offset = 4,
        size = 4,
        type = "VectorXYInt",
        what = "field"
      }, {
        address = "0x8",
        is = "int",
        name = "overrideIconColor",
        offset = 8,
        size = 4,
        type = "dword",
        unsigned = true,
        what = "field"
      }, {
        address = "0xc",
        is = "int",
        name = "frameRate",
        offset = 12,
        size = 1,
        type = "char",
        what = "field"
      }, {
        address = "0xd",
        fields = { {
            address = "0x0",
            is = "int",
            name = "useTextFromStringListInstead",
            offset = 0,
            size = 1,
            type = "byte",
            unsigned = true,
            what = "bitfield"
          }, {
            address = "0x0",
            is = "int",
            name = "overrideDefaultColor",
            offset = 1,
            size = 1,
            type = "byte",
            unsigned = true,
            what = "bitfield"
          }, {
            address = "0x0",
            is = "int",
            name = "widthOffsetIsAbsoluteIconWidth",
            offset = 2,
            size = 1,
            type = "byte",
            unsigned = true,
            what = "bitfield"
          } },
        is = "struct",
        metaName = "HUDInterfaceMessagingFlags",
        name = "moreFlags",
        offset = 13,
        size = 1,
        type = "HUDInterfaceMessagingFlags",
        what = "field"
      }, {
        address = "0xe",
        is = "int",
        name = "textIndex",
        offset = 14,
        size = 2,
        type = "word",
        unsigned = true,
        what = "field"
      }, {
        address = "0x10",
        count = 48,
        elementSize = 1,
        elementType = "char",
        is = "array",
        name = "pad7460",
        offset = 16,
        size = 48,
        what = "field"
      } },
    is = "struct",
    metaName = "HUDInterfaceMessagingInformation",
    name = "messagingInformation",
    offset = 316,
    size = 64,
    type = "HUDInterfaceMessagingInformation",
    what = "field"
  } }
