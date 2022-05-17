:- dynamic isBentrok/1.
:- dynamic jumlah_sks/2.
:- dynamic waktu/4.

prepare_semester :- 
    format('--- Selamat Datang di PrepareSemester! --- ~n'),
    format('~nMau ngapain?~n'),
    format('1. Lihat daftar semua mata kuliah~n'),
    format('2. Lihat semua jadwal mata kuliah~n'),
    format('3. Lihat jadwal suatu mata kuliah~n'),
    format('4. Lihat jadwal beberapa mata kuliah~n'),
    format('5. Susun jadwal kuliahmu~n'),
    format('6. Exit~n'),
    read(Command),
    proses_command(Command).

proses_command(6) :- format('--- Terima Kasih Sudah Menggunakan PrepareSemester ---'), !.
proses_command(Command) :-
    (Command = 1 -> lihat_semua_matkul;
    Command = 2 -> \+lihat_semua_jadwal;
    Command = 3 -> 
    	format('Masukkan nama matkul (lowercase), contoh: law'),
        read(Matkul),
    	(lihat_jadwal(Matkul) -> true;format('Matkul yang kamu masukkan tidak ada.~n~n'));
    Command = 4 -> 
    	format('Masukkan list matkul yang ingin dilihat, contoh: [law, datmin, prolog]'),
    	read(Matkuls),
        lihat_jadwal_pilihan(Matkuls);
    Command = 5 ->  
    	format('Masukkan list matkul pilihan kamu, contoh: [law, datmin, prolog, persdif]'),
    	read(Matkuls),
        format('Masukkan batas maksimum SKS kamu, contoh: 22'),
        read(MaxSks),
        cek_jadwal(Matkuls, MaxSks)),
    prepare_semester.

lihat_semua_matkul :-
    format('~n--- Daftar Mata Kuliah ---~n'),
    bagof( (Matkul-Sks), jumlah_sks(Matkul,Sks), List),
    maplist(print_matkul,List), nl.

print_matkul(Matkul-Sks) :-
    kapital(Matkul,MatkulUp),
    format('~w, ~w SKS~n',[MatkulUp, Sks]).

cek_jadwal(Matkuls, MaxSks) :-
    assert(isBentrok(false)),
    cek_jadwal_tidak_bentrok(Matkuls),
    print_jadwal_bentrok,
    (\+cek_batas_sks(Matkuls, MaxSks), format('Jumlah SKS yang diambil tidak melebihi maksimum SKS.~n~n')),
    (isBentrok(false) -> format('--- Jadwal Kuliahmu ---~n~n'), lihat_jadwal_pilihan(Matkuls);false).

cek_jadwal(_, _).

print_jadwal_bentrok :- (isBentrok(false) -> format('Jadwal matkul tidak ada yang bentrok.~n');true).

lihat_jadwal_pilihan([]).
lihat_jadwal_pilihan([H|T]) :-
    lihat_jadwal(H), lihat_jadwal_pilihan(T).

convert_ke_menit(Jam:Menit, TotalMenit) :-
    TotalMenit is (Jam * 60) + Menit.

pairs(Matkuls, Pairs) :-
    findall(X-Y, (append(_,[X|R],Matkuls), member(Y,R)), Pairs).

cek_jadwal_pairs([]).
cek_jadwal_pairs([Matkul1-Matkul2|T]) :-
    \+bentrok(Matkul1, Matkul2), cek_jadwal_pairs(T).

cek_jadwal_tidak_bentrok(Matkuls) :-
    pairs(Matkuls, Pairs),
    cek_jadwal_pairs(Pairs).

bentrok(Matkul1, Matkul2) :-
    waktu(Hari, Matkul1, Mulai1, Selesai1),
    waktu(Hari, Matkul2, Mulai2, Selesai2),
    convert_ke_menit(Mulai1, Mulai1Menit),
    convert_ke_menit(Selesai1, Selesai1Menit),
    convert_ke_menit(Mulai2, Mulai2Menit),
    convert_ke_menit(Selesai2, Selesai2Menit),
    cek_bentrok(Mulai1Menit,Selesai1Menit, Mulai2Menit, Selesai2Menit),
    format('Jadwal ~w bentrok dengan ~w.~n', [Matkul1,Matkul2]),
    retract(isBentrok(false)),
    assert(isBentrok(true)),
    fail.

cek_bentrok(T1, T2, T3, _) :-
    between(T1, T2, T3),!.

cek_bentrok(T1, T2, _, T4) :-
    between(T1, T2, T4),!.

cek_bentrok(T1, _, T3, T4) :-
    between(T3, T4, T1),!.

cek_bentrok(_, T2, T3, T4) :-
    between(T3, T4, T2),!.

hitung_sks([],0).
hitung_sks([H|T], JumlahSks) :-
    jumlah_sks(H, X),
    hitung_sks(T, Rest),
    JumlahSks is X + Rest.

cek_batas_sks(Matkuls, MaxSks) :-
    hitung_sks(Matkuls, JumlahSks),
    MaxSks < JumlahSks,
    format('Kamu mengambil ~w SKS. Jumlah SKS yang diambil melebihi maksimum SKS.~n~n', [JumlahSks]).

kapital(Kata,KataUp) :-
    atom_chars(Kata, [HurufPertamaCh|KataRest]),
    atom_chars(HurufPertama, [HurufPertamaCh]),
    upcase_atom(HurufPertama, HurufPertamaUp),
    atom_chars(HurufPertamaUp, [HurufPertamaUp]),
    atom_chars(KataUp, [HurufPertamaUp|KataRest]).

format_waktu(Jam:Menit, WaktuF) :-
    format_kurang_dari_10(Jam,JamF),
    format_kurang_dari_10(Menit,MenitF),
    string_concat(JamF,":",JamFNew),
    string_concat(JamFNew,MenitF,WaktuF).
format_kurang_dari_10(X, XF) :-
    (X < 10 -> string_concat("0",X,XF);XF is X).

print_jadwal(Hari-Mulai-Selesai) :-
    kapital(Hari,HariUp),
    format_waktu(Mulai, MulaiF),
    format_waktu(Selesai, SelesaiF),
    format('~w, ~w-~w WIB', [HariUp, MulaiF, SelesaiF]), nl.

lihat_jadwal(Matkul) :-
    bagof( (Hari-Mulai-Selesai), waktu(Hari, Matkul, Mulai, Selesai), List),
    jumlah_sks(Matkul, Sks),
    kapital(Matkul,MatkulUp),
    format('--- Jadwal Kuliah ~w (~w SKS) ---~n',[MatkulUp, Sks]),
    maplist(print_jadwal,List), nl.

lihat_semua_jadwal :-
    format('--- Jadwal Semua Mata Kuliah ---~n~n'),
    lihat_jadwal(_Matkul), fail.
