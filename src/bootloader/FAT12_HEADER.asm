; --------------------------------------------------------------
; FAT12 header
; --------------------------------------------------------------

bdb_oem:						db 'MSWIN4.1'					; 8 Bytes long
bdb_bytes_per_sector:			dw 0x0200						; 512 Bytes
bdb_sectors_per_cluster:		db 0x01							; 1
bdb_reserved_sectors:			dw 0x0001						; 1
bdb_fat_count:					db 0x02							; 2
bdb_dir_entries_count:			dw 0xE0							; 244
bdb_total_sectors:				dw 0x0B40						; 2880
bdb_media_descriptor_type:		db 0x0F0						; 0xF0 = 3.5" floppy disk
bdb_sectors_per_fat:			dw 0x0009						; 9 sectors/fat
bdb_sectors_per_track:			dw 0x0012						; 18 sectors/track
bdb_heads:						dw 0x0002						; 2
bdb_hidensectors:				dd 0x00000000					; 0
bdb_large_sector_count:			dd 0x00000000					; 0

; extended boot record
ebr_drive_number:				db 0x00							; 0x00 floppy, 0x80 hdd
win_NT_flags:					db 0x00							; reserved
ebr_signature:					db 0x29
ebr_volume_id:					db 0x01, 0x24, 0x19, 0x96		; Serial number
ebr_volume_label:				db 'OS Studies '				; 11 bytes long, space padded
ebr_system_id:					db 'FAT12   '					; 8 bytes long, space padded