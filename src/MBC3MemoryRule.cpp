/*
 * Gearboy - Nintendo Game Boy Emulator
 * Copyright (C) 2012  Ignacio Sanchez

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/ 
 * 
 */

#include "MBC3MemoryRule.h"
#include "Video.h"
#include "Memory.h"
#include "Processor.h"
#include "Input.h"
#include "Cartridge.h"

MBC3MemoryRule::MBC3MemoryRule(Processor* pProcessor,
        Memory* pMemory, Video* pVideo, Input* pInput,
        Cartridge* pCartridge, Audio* pAudio) : MemoryRule(pProcessor,
pMemory, pVideo, pInput, pCartridge, pAudio)
{
    m_iCurrentRAMBank = 0;
    m_iCurrentROMBank = 1;
    m_bRamEnabled = false;
    m_pRAMBanks = new u8[0x8000];
    Reset(false);
}

MBC3MemoryRule::~MBC3MemoryRule()
{
    SafeDeleteArray(m_pRAMBanks);
}

u8 MBC3MemoryRule::PerformRead(u16 address)
{
    if (address >= 0x4000 && address < 0x8000)
    {
        u8* pROM = m_pCartridge->GetTheROM();
        return pROM[(address - 0x4000) + (0x4000 * m_iCurrentROMBank)];
    }
    else if (m_bCGB && (address >= 0x8000 && address < 0xA000))
    {
        return m_pMemory->ReadCGBLCDRAM(address, false);
    }
    else if (address >= 0xA000 && address < 0xC000)
    {
        if (m_bRamEnabled)
        {
            return m_pRAMBanks[(address - 0xA000) + (0x2000 * m_iCurrentRAMBank)];
        }
        else
        {
            Log("--> ** Attempting to read from disabled ram %X", address);
            return 0x00;
        }
    }
    else if (m_bCGB && (address >= 0xD000 && address < 0xE000))
    {
        return m_pMemory->ReadCGBWRAM(address);
    }
    else if (address >= 0xFEA0 && address < 0xFF00)
    {
        // Empty area - GBC allows reading/writing to this area
        if (m_bCGB)
            return m_pMemory->Retrieve(address);
        else
            return ((((address + ((address >> 4) - 0x0FEA)) >> 2) & 1) ? 0x00 : 0xFF);
    }
    else
        return m_pMemory->Retrieve(address);
}

void MBC3MemoryRule::PerformWrite(u16 address, u8 value)
{
    if (address < 0x2000)
    {
        if (m_pCartridge->GetRAMSize() > 0)
            m_bRamEnabled = (value & 0x0F) == 0x0A;
    }
    else if (address >= 0x2000 && address < 0x4000)
    {
        m_iCurrentROMBank = value & 0x7F;
        if (m_iCurrentROMBank == 0)
            m_iCurrentROMBank = 1;
    }
    else if (address >= 0x4000 && address < 0x6000)
    {
        if ((value >= 0x08) && (value <= 0x0C))
        {
            // RTC
        }
        else
            m_iCurrentRAMBank = value & 0x03;
    }
    else if (address >= 0x6000 && address < 0x8000)
    {
        // RTC Latch
    }
    else if (m_bCGB && (address >= 0x8000 && address < 0xA000))
    {
        m_pMemory->WriteCGBLCDRAM(address, value);
    }
    else if (address >= 0xA000 && address < 0xC000)
    {
        if (m_bRamEnabled)
        {
            m_pRAMBanks[(address - 0xA000) + (0x2000 * m_iCurrentRAMBank)] = value;
        }
        else
        {
            Log("--> ** Attempting to write on RAM when ram is disabled %X %X", address, value);
        }
    }
    else if (address >= 0xC000 && address < 0xDE00)
    {
        if (m_bCGB && (address >= 0xD000))
        {
            m_pMemory->WriteCGBWRAM(address, value);
            m_pMemory->Load(address + 0x2000, value);
        }
        else
        {
            // Echo of 8K internal RAM
            m_pMemory->Load(address + 0x2000, value);
            m_pMemory->Load(address, value);
        }
    }
    else if (m_bCGB && (address >= 0xDE00 && address < 0xE000))
    {
        m_pMemory->WriteCGBWRAM(address, value);
    }
    else if (address >= 0xE000 && address < 0xFE00)
    {
        if (m_bCGB && (address >= 0xF000))
        {
            m_pMemory->WriteCGBWRAM(address - 0x2000, value);
            m_pMemory->Load(address, value);
        }
        else
        {
            // Echo of 8K internal RAM
            m_pMemory->Load(address - 0x2000, value);
            m_pMemory->Load(address, value);
        }
    }
    else if (address >= 0xFEA0 && address < 0xFF00)
    {
        // Empty area - GBC allows reading/writing to this area
        m_pMemory->Load(address, value);
    }
    else
    {
        m_pMemory->Load(address, value);
    }
}

void MBC3MemoryRule::Reset(bool bCGB)
{
    m_bCGB = bCGB;
    m_iCurrentRAMBank = 0;
    m_iCurrentROMBank = 0;
    m_bRamEnabled = false;
    for (int i = 0; i < 0x8000; i++)
        m_pRAMBanks[i] = 0;
}
