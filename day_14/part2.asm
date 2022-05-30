;;;  -*- tab-width: 10 -*-
          global    main
          extern    exit
          extern    fopen
          extern    fseek
          extern    ftell
          extern    fread
          extern    fclose
          extern    getline
          extern    malloc
          extern    calloc
          extern    free
          extern    strlen
          extern    printf
          extern    memcpy


          section   .text
open_file:                              ; FILE* open_file(char* fname);
          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x0
          mov       rsi, read_flag
          call      fopen
          leave
          ret


; Reads the first line, which is the initial polymer, as a table of pairs to counts.
; Populates first and last with the first and last characters of the polymer.
; Returns an array of length 32*32 (assumes 32 possible letters).
read_initial_polymer:                   ; uint64_t* read_initial_polymer(FILE* fp, uint8_t* first, uint8_t* last);
          ;; rbp-0x28: uint8_t* first
          ;; rbp-0x20: uint8_t* last
          ;; rbp-0x18: uint64_t* polymer
          ;; rbp-0x10: char* line
          ;; rbp-0x8:  int len
          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x30

          mov       [rbp-0x28], rsi      ; first
          mov       [rbp-0x20], rdx      ; last
          mov       rdx, rdi             ; fp

          ;; get the first line
          xor       rax, rax
          mov       [rbp-0x10], rax      ; clear line and line so getline allocs a new pointer
          mov       [rbp-0x8], rax
          lea       rdi, [rbp-0x10]      ; &line
          lea       rsi, [rbp-0x8]       ; &len
          call      getline              ; getline(&line, &len, fp)

          ;; populate the array
          mov       rdi, 32*32
          mov       rsi, 8
          call      calloc
          mov       rdi, rax             ; table

          ;; loop over the line, stopping on newline
          mov       rcx, 0               ; i
          mov       rsi, [rbp-0x10]      ; line
          ;; save first char
          mov       al, [rsi]
          mov       r8, [rbp-0x28]      ; first
          mov       [r8], al           ; *first = line[0]
.loop:
          mov       al, [rsi+rcx+1]      ; al = line[i+1]
          cmp       al, 0xa              ; while (line[i+1] != '\n')
          je        .done

          ;; combine the two letters into a single index
          movzx     rax, byte [rsi+rcx]  ; al = line[i]
          sub       rax, 0x41            ; al = al - 'A'
          and       rax, 0x1f            ; al = al & 0x1f (only use 5 bits)
          shl       rax, 5               ; al = al << 5
          mov       rdx, [rsi+rcx+1]     ; dl = line[i+1]
          sub       rdx, 0x41            ; dl = dl - 'A'
          and       rdx, 0x1f            ; dl = dl & 0x1f (only use 5 bits)
          or        rax, rdx             ; al = al | dl

          ;; increment the count for this pair
          inc       qword [rdi+rax*8]

          add       rcx, 1
          jmp .loop
.done:
          ;; save last char
          mov       al, [rsi+rcx]
          mov       r8, [rbp-0x20]      ; last
          mov       [r8], al           ; *last = line[i]

          mov       [rbp-0x18], rdi

          ;; free the line
          mov       rdi, [rbp-0x10]
          call      free

          ;; return the table
          mov       rax, [rbp-0x18]

          leave
          ret


; reads the polymer translation table
; assumes the fp is set to after the first line (after read_initial_polymer)
; returns an array of uint32_t of length 32*32
; each uint32_t is two uint16_t, which are indexes spawned by this translation
read_polymer_table:                     ; struct polymer* read_polymer_table(FILE* fp);
          ;; rbp-0x30: FILE* fp;
          ;; rbp-0x28: uint8_t buf[16];
          ;; rbp-0x10: uint32_t* table;
          ;; rbp-0x08: uint64_t fp_initial;

          push      rbp
          mov       rbp, rsp
          push      rbx
          sub       rsp, 0x38

          mov       [rbp-0x30], rdi     ; fp

          ; skip past the next blank line
          mov       rdi, [rbp-0x30]     ; fp
          mov       rsi, 1              ; offset = 1
          mov       rdx, 1              ; whence = SEEK_CUR (1)
          call      fseek               ; fseek(fp, 1, SEEK_CUR)

          ;; allocate the table
          mov       rdi, 32*32
          mov       rsi, 4
          call      calloc          ; table = calloc(32*32, 4)
          mov       [rbp-0x10], rax ; table

.read_loop:
          ;; Read one line at a time. Each line is a two byte template,
          ;; followed by 4 bytes of junk and a single byte replaced.
          lea       rdi, [rbp-0x28] ; buf
          mov       rsi, 1          ; size
          mov       rdx, 8          ; number of bytes to read
          mov       rcx, [rbp-0x30] ; fp
          call      fread           ; fread(buf, size, number, fp)
          test      rax, rax        ; check for end of file
          je        .done_reading

          ;; use first two bytes (template) as index into table
          lea       rsi, [rbp-0x28]
          ;; combine the two letters into a single index
          movzx     rax, byte [rsi] ; al = line[0]
          sub       rax, 0x41       ; al = al - 'A'
          and       rax, 0x1f       ; al = al & 0x1f (only use 5 bits)
          shl       rax, 5          ; al = al << 5
          mov       rdx, [rsi+1]    ; dl = line[1]
          sub       rdx, 0x41       ; dl = dl - 'A'
          and       rdx, 0x1f       ; dl = dl & 0x1f (only use 5 bits)
          or        rax, rdx        ; al = al | dl
          mov       r8, rax         ; save index to r8

          ;; maps to two packed uint16_t's:
          ;; one is made up of line[0] and line[6], the other is line[6] and line[1]
          movzx     rax, byte [rsi]   ; al = line[0]
          sub       rax, 0x41         ; al = al - 'A'
          and       rax, 0x1f         ; al = al & 0x1f (only use 5 bits)
          shl       rax, 5            ; al = al << 5
          mov       rdx, [rsi+6]      ; dl = line[6]
          sub       rdx, 0x41         ; dl = dl - 'A'
          and       rdx, 0x1f         ; dl = dl & 0x1f (only use 5 bits)
          or        rax, rdx          ; al = al | dl
          mov       r9, rax           ; first to save move to r9

          movzx     rax, byte [rsi+6] ; al = line[6]
          sub       rax, 0x41         ; al = al - 'A'
          and       rax, 0x1f         ; al = al & 0x1f (only use 5 bits)
          shl       rax, 5            ; al = al << 5
          mov       rdx, [rsi+1]      ; dl = line[6]
          sub       rdx, 0x41         ; dl = dl - 'A'
          and       rdx, 0x1f         ; dl = dl & 0x1f (only use 5 bits)
          or        rax, rdx          ; al = al | dl
          shl       r9, 16            ; r9 = r9 << 16
          or        r9, rax           ; second to save also save to r9

          mov       rdi, [rbp-0x10]   ; table
          mov       [rdi+r8*4], r9d   ; table[index] = r9
          jmp       .read_loop

.done_reading:
          mov       rax, [rbp-0x10]

          add       rsp, 0x38
          pop rbx
          leave
          ret

; Steps a polymer chain, adding to it based on table lookups
; Creates a new polymer chain
polymer_step:                   ; void polymer_step(uint32_t* table, uint64_t* polymer);
          ;; rbp-0x18: uint32_t* table;
          ;; rbp-0x10: uint64_t* old_polymer;
          ;; rbp-0x08: uint64_t* new_polymer;

          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x20

          mov       [rbp-0x18], rdi     ; table
          mov       [rbp-0x10], rsi     ; old_polymer

          ;; allocate a new chain
          mov       rdi, 32*32
          mov       rsi, 8
          call      calloc          ; table = calloc(32*32, 8)
          mov       [rbp-0x08], rax ; new_polymer

          ;; loop through the polymer chain, incrementing based on the table lookups
          mov       rdi, [rbp-0x18] ; table
          mov       rsi, [rbp-0x10] ; old_polymer
          mov       r9, [rbp-0x08] ; new_polymer
          mov       rcx, 0            ; i = 0
.loop:
          cmp       rcx, 1024         ; i < 1024 (32*32)
          je        .done
          mov       eax, [rdi+rcx*4]  ; rax = table[i]
          mov       r8, [rsi+rcx*8]   ; r8 = polymer[i] (increment by this amount)
          mov       rdx, rax
          and       rdx, 0xffff       ; first index is in low 16 bits
          add       [r9+rdx*8], r8   ; polymer[index] += r8
          mov       rdx, rax
          shr       rdx, 16           ; second index is in high 16 bits
          add       [r9+rdx*8], r8   ; polymer[index] += r8
          inc       rcx               ; i++
          jmp       .loop
.done:

          ;; free the old polymer chain
          mov       rdi, [rbp-0x10]
          call      free

          ;; return the new polymer chain
          mov       rax, [rbp-0x08]

          leave
          ret


;;; count difference between most common and least common elements
count_most_least_diff:          ; uint64_t count_most_least_diff(uint64_t* polymer, uint8_t first, uint8_t last);
          ;; rbp-0x100: uint64_t table[32];

          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x100

          mov       r8, rsi            ; r8 = first
          mov       r9, rdx            ; r9 = last

          lea       rsi, [rbp-0x100]  ; table

          ;; clear the table
          mov       rcx, 0
.clear_loop:
          mov       qword [rsi+rcx*8], 0
          inc       rcx
          cmp       rcx, 32
          jne       .clear_loop

          ;; loop through polymer chain, incrementing table based on count
          mov       rcx, 0            ; i = 0
.loop:
          cmp       rcx, 1024         ; i < 1024 (32*32)
          je        .done
          mov       rax, [rdi+rcx*8]  ; rax = table[i]
          mov       rdx, rcx
          and       rdx, 0x1f         ; first index is in low 5 bits
          add       [rsi+rdx*8], rax  ; table[index] = table[index] + rax
          mov       rdx, rcx
          shr       rdx, 5            ; second index is in high 5 bits
          add       [rsi+rdx*8], rax  ; table[index] = table[index] + rax
          inc       rcx               ; i++
          jmp       .loop
.done:
          ;; increment first and last chars because they were not counted twice
          sub       r8, 'A'     ; subtract 'A' to get index
          sub       r9, 'A'     ; subtract 'A' to get index
          inc       qword [rsi+r8*8]
          inc       qword [rsi+r9*8]

          ;; find the most common and least common chars
          mov       r8, 0       ; most_common = 0
          mov       r9, -1      ; least_common = -1
          mov       rcx, 0      ; i = 0
.loop2:
          mov       rax, [rsi+rcx*8]
          cmp       rax, 0
          jz        .next
          cmp       rax, r8     ; if rax > most_common
          cmova     r8, rax     ; most_common = rax
          cmp       rax, r9     ; if rax < least_common
          cmovb     r9, rax     ; least_common = rax
.next:
          inc       rcx
          cmp       rcx, 32
          jne       .loop2

          ;; return the difference
          sub       r8, r9
          shr       r8, 1       ; divide by 2 since all duplicated once
          mov       rax, r8

          leave
          ret


main:
          ;; rbp-0x1a: uint8_t first;
          ;; rbp-0x19: uint8_t second;
          ;; rbp-0x18: uint32_t* table; (array of length 32*32, maps pairs to 2 new pairs)
          ;; rbp-0x10: uint64_t* polymer; (array of length 32*32)
          ;; rbp-0x08: FILE* fp;

          push      rbp
          mov       rbp, rsp
          push      rbx
          sub       rsp, 0x28

          ;; open the file
          mov       rdi, file_name
          call      open_file
          mov       [rbp-0x8], rax     ; fp

          ;; read the initial polymer
          mov       rdi, [rbp-0x8]      ; fp
          lea       rsi, [rbp-0x1a]     ; first
          lea       rdx, [rbp-0x19]     ; second
          call      read_initial_polymer
          mov       [rbp-0x10], rax     ; polymer

          ;; read polymer table
          mov       rdi, [rbp-0x8]      ; fp
          call      read_polymer_table
          mov       [rbp-0x18], rax     ; table

          ;; step the polymer chain 10 times
          mov       rbx, 0
.loop:
          mov       rdi, [rbp-0x18]     ; table
          mov       rsi, [rbp-0x10]     ; polymer
          call      polymer_step
          mov       [rbp-0x10], rax     ; polymer
          inc       rbx
          cmp       rbx, 40
          jne       .loop

          ;; count the most and least common elements
          mov       rdi, [rbp-0x10]      ; polymer
          movzx     rsi, byte [rbp-0x1a] ; first
          movzx     rdx, byte [rbp-0x19] ; second
          call      count_most_least_diff

          ;; print the result
          mov       rdi, print_num
          mov       rsi, rax
          call      printf

          ;; cleanup
          mov       rdi, [rbp-0x8]
          call      fclose
          mov       rdi, [rbp-0x10]
          call      free
          mov       rdi, [rbp-0x18]
          call      free

          mov       rax, 0

          sub       rsp, 0x28
          pop       rbx
          leave
          ret


          section   .rdata
file_name:
          db        "input.txt", 0

read_flag:
          db        "r", 0

print_num:
          db        "%llu", 10, 0
