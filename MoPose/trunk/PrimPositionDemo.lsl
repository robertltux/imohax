// $Id$
//
// Copyright (c) 2008, Mo Hax
// All rights reserved.
//
// Simplified BSD License granted to all:
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright notice,
//         this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//         notice, this list of conditions and the following disclaimer in the
//         documentation and/or other materials provided with the distribution.
//     * Neither the name of Mo Hax nor the names of its contributors may be
//         used to endorse or promote products derived from this software
//         without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////

integer channel = 0;
integer whisper = FALSE;

vector last_pos;
rotation last_rot;
vector pos;
rotation rot;

say(string message)
{
    if (whisper) llWhisper(0,message);
    else llOwnerSay(message);
    if (channel != 0) llRegionSay(channel,message);
}

default
{
    state_entry()
    {
        pos = llGetPos();
        rot = llGetRot();
        last_pos = pos;
        last_rot = rot;
        say("Ready");
    }

    touch_start(integer num)
    {
        pos = llGetPos();
        rot = llGetRot();

        say(
            "\nRegion Coordinates:  " + (string) pos + "\n" +
            "Region Rotation:  " + (string) rot + "\n" +
            "Region Rotation (RAD):  " + (string) llRot2Euler(rot) + "\n" +
            "Region Rotation (DEG):  " + (string) (llRot2Euler(rot)*RAD_TO_DEG) + "\n" +
            "Last Region Coordinates:  " + (string) last_pos + "\n" +
            "Last Region Rotation:  " + (string) last_rot + "\n" +
            "Last Region Rotation (RAD):  " + (string) llRot2Euler(last_rot) + "\n" +
            "Last Region Rotation (DEG):  " + (string) (llRot2Euler(last_rot)*RAD_TO_DEG) + "\n" +
            "Offset in Position:  " + (string) ((pos - last_pos)/last_rot + "\n" +
            "Offset in Rotation:  " + (string) (rot / last_rot) + "\n" +
            "Offset in Rotation (RAD):  " + (string) llRot2Euler(rot/last_rot) + "\n" +
            "Offset in Rotation (DEG):  " + (string) (llRot2Euler(rot/last_rot)*RAD_TO_DEG) + "\n"
            );

        last_pos = pos;
        last_rot = rot;
    }
}