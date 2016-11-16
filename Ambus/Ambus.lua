--[[Copyright © 2016, Hugh Broome
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Hugh Broome BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]--

_addon.name     = 'Ambus'
_addon.author   = 'Lygre'
_addon.version  = '1.0.1'
_addon.commands = {'ambus'}

require('luau')
require('pack')
require('lists')
require('logger')
require('sets')
files = require('files')
extdata = require('extdata')
packets = require('packets')
require('chat')
res = require('resources')

local pkt = {}

local npc = 17797269
local target_index = 149
local menu = 387
local zone = 249
local cape_name = ""
local aug_name = ""
local opt_ind 
local path_item = ''
local menu_params

local abdhaljs = {
	['Thread'] = {
		[0] = 'HP',
		[1] = 'MP',
		[2] = 'STR',
		[3] = 'DEX',
		[4] = 'VIT',
		[5] = 'AGI',
		[6] = 'INT',
		[7] = 'MND',
		[8] = 'CHR',
		[9] = 'PetMelee',
		[10] = 'PetMagic'},
	['Dust'] = {
		[0] = 'Acc/Atk',
		[1] = 'RAcc/RAtk',
		[2] = 'MAcc/MDmg',
		[3] = 'Eva/MEva'},
	['Sap'] = {
		[0] = 'WSD',
		[1] = 'CritRate',
		[2] = 'STP',
		[3] = 'DoubleAttack',
		[4] = 'Haste',
		[5] = 'DW',
		[6] = 'Enmity+',
		[7] = 'Enmity-',
		[8] = 'Snapshot',
		[9] = 'MAB',
		[10] = 'FC',
		[11] = 'CurePotency',
		[12] = 'WaltzPotency',
		[13] = 'PetRegen',
		[14] = 'PetHaste',},
	['Dye'] = {
		[0] = 'HP',
		[1] = 'MP',
		[2] = 'STR',
		[3] = 'DEX',
		[4] = 'VIT',
		[5] = 'AGI',
		[6] = 'INT',
		[7] = 'MND',
		[8] = 'CHR',
		[9] = 'Acc',
		[10] = 'Atk',
		[11] = 'Ranged Acc',
		[12] = 'Ranged Atk',
		[13] = 'MAcc',
		[14] = 'MDmg',
		[15] = 'Evasion',
		[16] = 'MEvasion',
		[17] = 'PetAcc',
		[18] = 'PetAtk',
		[19] = 'PetMAcc',
		[20] = 'PetMDmg',},
}
local busy = false

windower.register_event('addon command', function(...)
	local args = T{...}
	local cmd = args[1]
	args:remove(1)	
	if cmd == 'item' then
		if S{'Sap','Dye','Thread','Dust'}:contains(args[1]) then
			if args[4] then
				aug_name = 'Abdhaljs '..args[1]..''
				path_item = args[1]
				cape_name = ''..args[2]..' '..args[3]..''
				for i,v in ipairs(abdhaljs[path_item]) do
					if args[4]:lower() == v:lower() then
						opt_ind = i 
					end
				end
			end
		else 
			windower.add_to_chat(2, 'incorrect augment item')
		end
	elseif cmd == 'go' then
		pkt = validate()
		busy = true
		build_trade()
	elseif cmd == 'setup' then
		setup_cape()
	end
end)

function setup_cape()
	cape_ind = get_item_index(cape_name)
	aug_ind = get_item_index(aug_name)
	print(cape_name,cape_ind)
	print(aug_name,aug_ind,path_item,opt_ind)
end

function get_item_index(item_name)
	local inventory = windower.ffxi.get_items(0)
	local item = res.items:with('name', item_name)
	for k, v in pairs(inventory) do
		if v.id == item.id then
			return k 
		end
	end
end

function build_trade()
	if npc and target_index then
		local packet = packets.new('outgoing', 0x036, {
			["Target"]=npc,
			["Target Index"]=target_index,
			["Item Count 1"]=1,
			["Item Count 2"]=1,
			["Item Index 1"]=cape_ind,
			["Item Index 2"]=aug_ind,
			["Number of Items"]=2})
		packets.inject(packet)
	end
end

function validate()
	local zone = windower.ffxi.get_info()['zone']
	local me
	local result = {}
	for i,v in pairs(windower.ffxi.get_mob_array()) do
		if v['name'] == windower.ffxi.get_player().name then
			result['me'] = i
		end
	end
	return result 
end


windower.register_event('incoming chunk',function(id,data,modified,injected,blocked)
    if id == 0x034 or id == 0x032 then
        if busy == true and pkt then
	        local packet = packets.new('outgoing', 0x05B)
	        packet["Target"]=npc
	        packet["Option Index"]=256
	        packet["_unknown1"]=opt_ind
	        packet["Target Index"]=target_index
	        packet["Automated Message"]=true
	        packet["_unknown2"]=0
	        packet["Zone"]=zone
	        packet["Menu ID"]=menu
	        packets.inject(packet)

	        local packet = packets.new('outgoing', 0x05B)
	        packet["Target"]=npc
	        packet["Option Index"]=256
	        packet["_unknown1"]=opt_ind
	        packet["Target Index"]=target_index
	        packet["Automated Message"]=false
	        packet["_unknown2"]=0
	        packet["Zone"]=zone
	        packet["Menu ID"]=menu
	        packets.inject(packet)
	        local packet = packets.new('outgoing', 0x016, {
	        ["Target Index"]=pkt['me'],
	        })
	        packets.inject(packet)
	        busy = false
	        pkt = {}
	        return true
        end
    end
end)
