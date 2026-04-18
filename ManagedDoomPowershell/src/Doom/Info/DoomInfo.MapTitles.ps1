##
## Copyright (C) 1993-1996 Id Software, Inc.
## Copyright (C) 2019-2020 Nobuaki Tanaka
## Copyright (C) 2026 Oleyska
##
## This file is a PowerShell port / modified version of code from ManagedDoom.
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##


class MapTitles {
    [System.Collections.Generic.List[object]] $Doom = @(
        @(
            "HUSTR_E1M1", "HUSTR_E1M2", "HUSTR_E1M3", "HUSTR_E1M4", "HUSTR_E1M5",
            "HUSTR_E1M6", "HUSTR_E1M7", "HUSTR_E1M8", "HUSTR_E1M9"
        ),
        @(
            "HUSTR_E2M1", "HUSTR_E2M2", "HUSTR_E2M3", "HUSTR_E2M4", "HUSTR_E2M5",
            "HUSTR_E2M6", "HUSTR_E2M7", "HUSTR_E2M8", "HUSTR_E2M9"
        ),
        @(
            "HUSTR_E3M1", "HUSTR_E3M2", "HUSTR_E3M3", "HUSTR_E3M4", "HUSTR_E3M5",
            "HUSTR_E3M6", "HUSTR_E3M7", "HUSTR_E3M8", "HUSTR_E3M9"
        ),
        @(
            "HUSTR_E4M1", "HUSTR_E4M2", "HUSTR_E4M3", "HUSTR_E4M4", "HUSTR_E4M5",
            "HUSTR_E4M6", "HUSTR_E4M7", "HUSTR_E4M8", "HUSTR_E4M9"
        )
    )

    [System.Collections.Generic.List[string]] $Doom2 = @(
        "HUSTR_1", "HUSTR_2", "HUSTR_3", "HUSTR_4", "HUSTR_5", "HUSTR_6", "HUSTR_7",
        "HUSTR_8", "HUSTR_9", "HUSTR_10", "HUSTR_11", "HUSTR_12", "HUSTR_13",
        "HUSTR_14", "HUSTR_15", "HUSTR_16", "HUSTR_17", "HUSTR_18", "HUSTR_19",
        "HUSTR_20", "HUSTR_21", "HUSTR_22", "HUSTR_23", "HUSTR_24", "HUSTR_25",
        "HUSTR_26", "HUSTR_27", "HUSTR_28", "HUSTR_29", "HUSTR_30", "HUSTR_31",
        "HUSTR_32"
    )

    [System.Collections.Generic.List[string]] $Plutonia = @(
        "PHUSTR_1", "PHUSTR_2", "PHUSTR_3", "PHUSTR_4", "PHUSTR_5", "PHUSTR_6",
        "PHUSTR_7", "PHUSTR_8", "PHUSTR_9", "PHUSTR_10", "PHUSTR_11", "PHUSTR_12",
        "PHUSTR_13", "PHUSTR_14", "PHUSTR_15", "PHUSTR_16", "PHUSTR_17",
        "PHUSTR_18", "PHUSTR_19", "PHUSTR_20", "PHUSTR_21", "PHUSTR_22",
        "PHUSTR_23", "PHUSTR_24", "PHUSTR_25", "PHUSTR_26", "PHUSTR_27",
        "PHUSTR_28", "PHUSTR_29", "PHUSTR_30", "PHUSTR_31", "PHUSTR_32"
    )

    [System.Collections.Generic.List[string]] $Tnt = @(
        "THUSTR_1", "THUSTR_2", "THUSTR_3", "THUSTR_4", "THUSTR_5", "THUSTR_6",
        "THUSTR_7", "THUSTR_8", "THUSTR_9", "THUSTR_10", "THUSTR_11", "THUSTR_12",
        "THUSTR_13", "THUSTR_14", "THUSTR_15", "THUSTR_16", "THUSTR_17",
        "THUSTR_18", "THUSTR_19", "THUSTR_20", "THUSTR_21", "THUSTR_22",
        "THUSTR_23", "THUSTR_24", "THUSTR_25", "THUSTR_26", "THUSTR_27",
        "THUSTR_28", "THUSTR_29", "THUSTR_30", "THUSTR_31", "THUSTR_32"
    )
}