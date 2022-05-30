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


          section   .text
open_file:                              ; FILE* open_file(char* fname);
          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x0
          mov       rsi, read_flag
          call      fopen
          leave
          ret


; reads the first line, which is the initial polymer
; returns a malloc'ed pointer to the data
read_initial_polymer:                   ; char* read_initial_polymer(FILE* fp);
          ;; rbp-0x10: char* line
          ;; rbp-0x8:  int len
          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x10

          mov       rdx, rdi            ; fp

          ;; get the first line
          xor       rax, rax
          mov       [rbp-0x10], rax     ; clear line and line so getline allocs a new pointer
          mov       [rbp-0x8], rax
          lea       rdi, [rbp-0x10]     ; &line
          lea       rsi, [rbp-0x8]      ; &len
          call      getline             ; getline(&line, &len, fp)

          ;; set null terminator at end of line (newline)
          mov       rcx, [rbp-0x10]     ; line
.loop:
          mov       al, [rcx]
          add       rcx, 0x1
          cmp       al, 0xa     ; newline
          jne       .loop
          mov       byte [rcx-1], 0

          mov       rax, [rbp-0x10]     ; line

          leave
          ret


; reads the polymer translation table
; assumes the fp is set to after the first line (after read_initial_polymer)
; returns an array of structs of the form:
; struct polymer {
;         uint16_t template;
;         uint8_t replaced;
;         uint8_t PADDING;
; };
read_polymer_table:                     ; struct polymer* read_polymer_table(FILE* fp);
          ;; rbp-0x30: FILE* fp;
          ;; rbp-0x28: uint8_t buf[16];
          ;; rbp-0x18: uint64_t buf_len;
          ;; rbp-0x10: struct polymer* table;
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

          ; save the current position for calculating the length later
          mov       rdi, [rbp-0x30]     ; fp
          call      ftell               ; ftell(fp)
          mov       [rbp-0x8], rax

          ; skip to the end of the file to calculate the length
          mov       rdi, [rbp-0x30]     ; fp
          mov       rsi, 0              ; offset = 0
          mov       rdx, 2              ; whence = SEEK_END (2)
          call      fseek               ; fseek(fp, 0, SEEK_END)

          mov       rdi, [rbp-0x30]     ; fp
          call      ftell               ; ftell(fp)

          ; subtract start from end for the length
          sub       rax, [rbp-0x8]      ; rax -= fp_initial
          ; length should be divisible by 8
          test      rax, 0x7
          jz        .ok_length
          mov       rdi, 2              ; exit code (2)
          call      exit                ; ERROR: rest of file length not divisible by 8
.ok_length:
          shr       rax, 3              ; length /= 8
          mov       [rbp-0x18], rax     ; set buf_len


          ; seek back to start of polymer table
          mov       rdi, [rbp-0x30] ; fp
          mov       rsi, [rbp-0x8]  ; offset = fp_initial
          mov       rdx, 0          ; whence = SEEK_SET (0)
          call      fseek           ; fseek(fp, fp_initial, SEEK_SET)

          ;; allocate the table
          mov       rdi, [rbp-0x18] ; length
          add       rdi, 1          ; add one for the null terminator
          shl       rdi, 3          ; length *= 8 (8 bytes per struct)
          call      malloc          ; table = malloc(length)
          mov       [rbp-0x10], rax ; table

          mov       rbx, [rbp-0x10] ; current table value
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

          ;; copy first two bytes (template) to table
          lea       rsi, [rbp-0x28]
          xor       rax, rax
          mov       ax, [rsi+0x0]
          mov       [rbx], rax
          ;; copy 6th byte (replaced) to table
          xor       rax, rax
          mov       al, [rsi+0x6]
          mov       [rbx+0x2], ax

          add       rbx, 4
          jmp       .read_loop

.done_reading:
          mov       rax, [rbp-0x10]

          add       rsp, 0x38
          pop rbx
          leave
          ret

; Looks up the polymer translation table and returns the template for a given
; polymer pair.
polymer_table_lookup:           ; char polymer_table_lookup(struct polymer* table, uint16_t polymer_pair);
          push rbp
          mov rbp, rsp

          ;; step through the table until we find the template
          sub rdi, 4
.loop:
          add rdi, 4
          cmp word [rdi], 0  ; reached the end of the table?
          je .error          ; if so, couldn't find the template
          cmp word [rdi], si ; is this the template we're looking for?
          jne .loop          ; if not, keep looking

          ;; if we get here, we found the template
          movzx rax, byte [rdi+2] ; return the replaced byte

          leave
          ret

.error:
          mov rdi, 3            ; ERROR: template not found
          call exit


; Runs one iteration of polymer expansion, returning a new string. A polymer
; chain of length x grows to length 2x-1.
polymer_step:                   ; char* polymer_step(struct polymer* table, char* polymer);
          ;; rbp-0x20: uint64_t old_polymer_len;
          ;; rbp-0x18: char* new_polymer
          ;; rbp-0x10: char* old_polymer
          ;; rbp-0x08: struct polymer* table

          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x20

          mov       [rbp-0x8], rdi      ; table
          mov       [rbp-0x10], rsi     ; old_polymer

          ;; get the length of the old polymer
          mov       rdi, [rbp-0x10]     ; old_polymer
          call      strlen              ; strlen(old_polymer)
          mov       [rbp-0x20], rax     ; old_polymer_len

          ;; allocate the new polymer
          shl       rax, 1              ; length *= 2 (2x - 1, and add 1 for null terminator)
          mov       rdi, rax            ; length
          call      malloc              ; new_polymer = malloc(length)
          mov       [rbp-0x18], rax     ; new_polymer

          ;; loop over old polymer
          mov       rcx, 0              ; i = 0
.loop:
          mov       rax, rcx
          add       rax, 1
          cmp       rax, [rbp-0x20]
          je       .done                ; while i + 1 < old_polymer_len

          ;; lookup [i] + [i+1] in the table
          mov       rdx, [rbp-0x10]     ; old_polymer
          movzx     rsi, word [rdx+rcx] ; [i] and [i+1]
          mov       rdi, [rbp-0x8]      ; table
          call      polymer_table_lookup ; template = polymer_table_lookup(table, [i] + [i+1])

          ;; place results into new polymer
          mov       rsi, [rbp-0x10]     ; old_polymer
          mov       rdi, [rbp-0x18] ; new_polymer
          mov       dl, [rsi+rcx]   ; [i]
          mov       [rdi+rcx*2+0], dl
          mov       dl, al          ; template
          mov       [rdi+rcx*2+1], dl
          mov       dl, [rsi+rcx+1] ; [i+1]
          mov       [rdi+rcx*2+2], dl

          add       rcx, 1              ; i++
          jmp      .loop
.done:

          ;; free old polymer
          mov       rdi, [rbp-0x10]     ; old_polymer
          call      free                ; free(old_polymer)

          mov       rax, [rbp-0x18]     ; new_polymer

          leave
          ret


; Counts the most common letter and least common letter in a polymer chain.
; Returns the difference between the two number of occurrences.
count_most_least_diff:          ; int count_most_least_diff(char* polymer);
          ;; rbp-0x18: uint64_t diff;
          ;; rbp-0x10: uint64_t* count_table; (table of counts, 1 for each possible byte)
          ;; rbp-0x08: char* polymer

          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x20

          mov       [rbp-0x8], rdi     ; polymer

          ;; allocate the count table
          mov       rdi, 256            ; number of bytes
          mov       rsi, 8              ; 8 bytes per count
          call      calloc              ; count_table = calloc(256, 8)
          mov       [rbp-0x10], rax     ; count_table

          ;; loop over polymer
          mov       rcx, [rbp-0x8]      ; polymer
          mov       rdi, [rbp-0x10]     ; count_table
.polymer_loop:
          movzx     rax, byte [rcx]
          inc       qword [rdi+rax*8]   ; count_table[polymer[i]]++
          add       rcx, 1
          cmp       byte [rcx], 0
          jne       .polymer_loop

          ;; find the most common and least common letter
          mov       rdi, [rbp-0x10]     ; count_table
          mov       r8, 0               ; most_common
          mov       r9, 0xffffffffffffffff ; least_common
          mov       rcx, 0              ; i = 0
.find_most_least_loop:
          mov       rax, [rdi+rcx*8]       ; count_table[i]
          cmp       rax, 0                 ; ignore 0 counts
          je        .next2
          cmp       rax, r8              ; if (count_table[i] > most_common)
          jbe       .next1
          mov       r8, rax              ; most_common = count_table[i]
.next1:
          cmp       rax, r9              ; if (count_table[i] < least_common)
          jae       .next2
          mov       r9, rax              ; least_common = count_table[i]
.next2:

          add       rcx, 1
          cmp       rcx, 256
          jne       .find_most_least_loop

          ;; calculate the difference
          sub       r8, r9
          mov       [rbp-0x18], r8

          ;; free the count table
          mov       rdi, [rbp-0x10]     ; count_table
          call      free                ; free(count_table)

          mov       rax, [rbp-0x18]     ; diff

          leave
          ret

main:
          ;; rbp-0x20: uint64_t i;
          ;; rbp-0x18: char* line;
          ;; rbp-0x10: struct polymer* table;
          ;; rbp-0x08: FILE* fp;

          push      rbp
          mov       rbp, rsp
          sub       rsp, 0x20

          ;; open the file
          mov       rdi, file_name
          call      open_file
          mov       [rbp-0x8], rax     ; fp

          ;; read the initial polymer
          mov       rdi, [rbp-0x8]      ; fp
          call      read_initial_polymer
          mov       [rbp-0x18], rax     ; line

          ;; read the polymer table
          mov       rdi, [rbp-0x8]      ; fp
          call      read_polymer_table
          mov       [rbp-0x10], rax     ; table

          ;; run polymer step 10 times
.loop:
          cmp       qword [rbp-0x20], 10      ; i < 10
          je        .done               ; if so, we're done

          ;; step through 1 iteration of polymer expansion
          mov       rdi, [rbp-0x10]     ; table
          mov       rsi, [rbp-0x18]     ; line
          call      polymer_step
          mov       [rbp-0x18], rax     ; line

          add       qword [rbp-0x20], 1       ; i++
          jmp       .loop
.done:

          ;; count the most common and least common element
          mov       rdi, [rbp-0x18]     ; line
          call      count_most_least_diff

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
          leave
          ret


          section   .rdata
file_name:
          db        "input.txt", 0

read_flag:
          db        "r", 0

print_num:
          db        "%d", 10, 0
