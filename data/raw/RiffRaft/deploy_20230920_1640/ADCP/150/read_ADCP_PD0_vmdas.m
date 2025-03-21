function tbytes=read_ADCP_PD0_v2(infile,ofile)
clear global
global nbytes offsets ntypes tbytes cfg data btdata navdata iens
%infile='arctrex2014011_000000.ENX';




fid=fopen(infile,'r');

firstens=find_first_ensemble(fid);

d=dir(infile);
if firstens==0
    nens=floor((d.bytes-(firstens))/nbytes);
else
    nens=floor((d.bytes-(firstens-1))/nbytes);
end

fseek(fid,firstens,'bof');
tbytes=fread(fid,abs(nbytes)+2,'uint8=>uint8');
read_header(tbytes);
read_fixed(tbytes,1);

data=struct('ensemble',zeros(1,1),...
    'time',zeros(1,1),...
    'heading',zeros(1,1),...
    'pitch',zeros(1,1),...
    'roll',zeros(1,1),...
    'temperature',zeros(1,1),...
    'pressure',zeros(1,1),...
    'u1',zeros(cfg.nbins,1),...
    'u2',zeros(cfg.nbins,1),...
    'u3',zeros(cfg.nbins,1),...
    'u4',zeros(cfg.nbins,1),...
    'c1',zeros(cfg.nbins,1),...
    'c2',zeros(cfg.nbins,1),...
    'c3',zeros(cfg.nbins,1),...
    'c4',zeros(cfg.nbins,1),...
    'ei1',zeros(cfg.nbins,1),...
    'ei2',zeros(cfg.nbins,1),...
    'ei3',zeros(cfg.nbins,1),...
    'ei4',zeros(cfg.nbins,1),...
    'pg1',zeros(cfg.nbins,1),...
    'pg2',zeros(cfg.nbins,1),...
    'pg3',zeros(cfg.nbins,1),...
    'pg4',zeros(cfg.nbins,1));



btdata=struct('r1',zeros(1,1),...
    'r2',zeros(1,1),...
    'r3',zeros(1,1),...
    'r4',zeros(1,1),...
    'v1',zeros(1,1),...
    'v2',zeros(1,1),...
    'v3',zeros(1,1),...
    'v4',zeros(1,1),...
    'lat',zeros(1,1),...
    'lon',zeros(1,1));

navdata=struct('time',zeros(1,1),...
    'flat',zeros(1,1),...
    'flon',zeros(1,1),...
    'llat',zeros(1,1),...
    'llon',zeros(1,1),...
    'spd',zeros(1,1),...
    'spdmg',zeros(1,1),...
    'dirmg',zeros(1,1),...
    'utrue',zeros(1,1),...
    'vtrue',zeros(1,1),...
    'dirtrue',zeros(1,1),...
    'dirmag',zeros(1,1));



fseek(fid,firstens,'bof');
N=100;
iens=1;
while 1
    %for ibn=1:10
    
    if rem(iens,100)==0
        s1=sprintf('%d',iens);
        s2=sprintf('%d',nens);
        disp(['Read ' s1 ' of ~' s2 ' ensembles.'])
    end
    
    tbytes=fread(fid,N,'uint8=>uint8');
    
    if length(tbytes)==0
        disp('DONE')
        break
    end
    read_header(tbytes);
    fseek(fid,-N,'cof');
    tbytes=fread(fid,nbytes+2,'uint8=>uint8');
    
    
    
    
    if length(tbytes) < nbytes
        disp('DONE')
        break
    end
    %   read_header(tbytes);
    
    for idt=1:ntypes
        %     [idt ntypes nbytes]
        stind=offsets(idt);
        id1=dec2hex(tbytes(stind+1),2);
        id2=dec2hex(tbytes(stind+2),2);
        ID=[id2 id1];
        %         disp(ID)
        switch ID
            case '0000' %Fixed leader
                read_fixed(tbytes,idt);
            case '0080' %variable leader
                read_VL(tbytes,idt);
            case '0100' % UVW
                read_UV(tbytes,idt);
            case '0200' %CORR
                read_CORR(tbytes,idt);
            case '0300' %EI
                read_EI(tbytes,idt);
            case '0400' %PG
                read_PG(tbytes,idt);
            case '0600'
                read_BT(tbytes,idt);
            case '2000'
                read_vmdasnav(tbytes,idt);
            case '2100'
                read_2100(tbytes,idt);
            case '2101'
                read_2101(tbytes,idt);
            case '2102'
                read_2102(tbytes,idt);
            case '2022'
                read_2022(tbytes,idt);
        end
        
        
    end
    %
    %
    %
    %
    %
    %
    %pause
    iens=iens+1;
end

s1=sprintf('%d',iens-1);
s2=sprintf('%d',nens);
disp(['Read ' s1 ' of ~' s2 ' ensembles.'])

fclose(fid);
bins=((([1:double(cfg.nbins)]-1)*double(cfg.binsize))+double(cfg.bin1))/100;
disp(['Saving data to file.'])
save(ofile,'data','cfg','btdata','navdata','bins')
disp('All Done, you may return to regularly scheduled programming')

end
function read_header(tbytes)
global offsets  ntypes nbytes

HID=dec2hex(tbytes(1));
HID2=dec2hex(tbytes(2));
% disp([HID HID2])
nbytes=typecast(tbytes(3:4), 'int16');
ntypes=tbytes(6);
ind=1;
for in=1:ntypes
    offsets(in)=typecast([ tbytes(6+ind) tbytes(6+ind+1)], 'uint16');
    ind=ind+2;
end
end

function read_fixed(tbytes,idt)
global offsets cfg
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
cpufwv=tbytes(stind+3);
cpufwr=tbytes(stind+4);

config1=dec2base(tbytes(stind+5),2,8);

switch config1(6:8)
    case '000'
        cfg.freq=75;
    case '001'
        cfg.freq=150;
    case '010'
        cfg.freq=300;
    case '011'
        cfg.freq=600;
    case '100'
        cfg.freq=1200;
    case '101'
        cfg.freq=2400;
end

config2=dec2base(tbytes(stind+6),2,8);


flag=tbytes(stind+7);
cfg.laglength=tbytes(stind+8);
cfg.nbeam=tbytes(stind+9);
cfg.nbins=tbytes(stind+10);
cfg.wp=typecast(tbytes(stind+[11:12]), 'uint16');
cfg.binsize=typecast(tbytes(stind+[13:14]), 'uint16');
cfg.wf=typecast(tbytes(stind+[15:16]), 'uint16');
cfg.wm=tbytes(stind+[17]);
cfg.lct=tbytes(stind+[18]);
cfg.coderep=tbytes(stind+[19]);
cfg.WG=tbytes(stind+[20]);
cfg.we=typecast(tbytes(stind+[21:22]), 'uint16');
cfg.tppmin=tbytes(stind+[23]);
cfg.tppsec=tbytes(stind+[24]);
cfg.tpphun=tbytes(stind+[25]);
cfg.EX=dec2base(tbytes(stind+26),2,8);
cfg.EA=typecast(tbytes(stind+[27:28]), 'uint16');
cfg.EB=typecast(tbytes(stind+[29:30]), 'uint16');
cfg.EZ=dec2base(tbytes(stind+31),2,8);
cfg.SA=dec2base(tbytes(stind+32),2,8);
cfg.bin1=typecast(tbytes(stind+[33:34]), 'uint16');
cfg.xmitlength=typecast(tbytes(stind+[35:36]), 'uint16');
cfg.wmrefave=typecast(tbytes(stind+[37:38]), 'uint16');
falsetarget=tbytes(stind+[39]);
spare=tbytes(stind+[40]);
tlaglen=typecast(tbytes(stind+[41:42]), 'uint16');
cpusn=dec2hex(tbytes(stind+[43:50]));
sysband=typecast(tbytes(stind+[51:52]), 'uint16');
syspower=tbytes(stind+[53]);
instrsn=tbytes(stind+[55:58]);
cfg.bmangle=tbytes(stind+[59]);







end

function read_VL(tbytes,idt)
global offsets cfg data iens
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
ens=typecast(tbytes(stind+[3:4]), 'uint16');
datetime=double(tbytes(stind+[5:11]));
yy=datetime(1)+2000;
mm=datetime(2);
dd=datetime(3);
hh=datetime(4);
mi=datetime(5);
ss=datetime(6)+datetime(7)/100.0;
data.time(iens)=datenum(yy,mm,dd,hh,mi,ss);
%datestr(data.time(iens));
ensmsb=tbytes(stind+[12]);
BIT=typecast(tbytes(stind+[13:14]), 'uint16');
soundspd=typecast(tbytes(stind+[15:16]), 'uint16');
transdep=typecast(tbytes(stind+[17:18]), 'uint16');
data.heading(iens)=double(typecast(tbytes(stind+[19:20]), 'uint16'))/100.0;
data.pitch(iens)=double(typecast(tbytes(stind+[21:22]), 'int16'))/100.0;
data.roll(iens)=double(typecast(tbytes(stind+[23:24]), 'int16'))/100.0;
salinity=typecast(tbytes(stind+[25:26]), 'int16');
data.temperature(iens)=double(typecast(tbytes(stind+[27:28]), 'int16'))/100;
mpttime=tbytes(stind+[29:31])';
HPRstdev=tbytes(stind+[32:34])';
ADC=tbytes(stind+[35:42])';
errstat1=dec2base(tbytes(stind+43),2,8);
errstat2=dec2base(tbytes(stind+44),2,8);
errstat3=dec2base(tbytes(stind+45),2,8);
errstat4=dec2base(tbytes(stind+46),2,8);
spare=typecast(tbytes(stind+[47:48]), 'int16');
data.pressure(iens)=double(typecast(tbytes(stind+[49:52]), 'int32'))*0.001;
prrssurevar=typecast(tbytes(stind+[53:56]), 'int32');
spare=tbytes(stind+57);
rtctime=tbytes(stind+[58:65])';

end

function read_UV(tbytes,idt)
global offsets data cfg iens
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
nread=int16(cfg.nbins)*4*2;
tu=double(typecast(tbytes(stind+2+[1:nread]), 'int16'));
tu=reshape(tu,[4 cfg.nbins]);
data.u1(:,iens)=tu(1,:);
data.u2(:,iens)=tu(2,:);
data.u3(:,iens)=tu(3,:);
data.u4(:,iens)=tu(4,:);

end

function read_CORR(tbytes,idt)
global offsets data cfg iens
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
nread=int16(cfg.nbins)*4;
tu=double(tbytes(stind+2+[1:nread]));
tu=reshape(tu,[4 cfg.nbins]);

data.c1(:,iens)=tu(1,:);
data.c2(:,iens)=tu(2,:);
data.c3(:,iens)=tu(3,:);
data.c4(:,iens)=tu(4,:);

end
function read_EI(tbytes,idt)
global offsets data cfg iens
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
nread=int16(cfg.nbins)*4;
tu=double(tbytes(stind+2+[1:nread]));
tu=reshape(tu,[4 cfg.nbins]);

data.ei1(:,iens)=tu(1,:);
data.ei2(:,iens)=tu(2,:);
data.ei3(:,iens)=tu(3,:);
data.ei4(:,iens)=tu(4,:);


end
function read_PG(tbytes,idt)
global offsets data cfg iens
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);

nread=int16(cfg.nbins)*4;
tu=double(tbytes(stind+2+[1:nread]));
tu=reshape(tu,[4 cfg.nbins]);

data.pg1(:,iens)=tu(1,:);
data.pg2(:,iens)=tu(2,:);
data.pg3(:,iens)=tu(3,:);
data.pg4(:,iens)=tu(4,:);

end

function read_BT(tbytes,idt)
global offsets  iens btdata
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
BP=typecast(tbytes(stind+[3:4]), 'uint16');
BD=typecast(tbytes(stind+[5:6]), 'uint16');
BC=tbytes(stind+[7]);
BA=tbytes(stind+[8]);
BG=tbytes(stind+[9]);
BX=tbytes(stind+[10]);
BE=typecast(tbytes(stind+[11:12]), 'int16');
BTR=double(typecast(tbytes(stind+[17:24]), 'int16'));
btdata.r1(iens)=BTR(1);
btdata.r2(iens)=BTR(2);
btdata.r3(iens)=BTR(3);
btdata.r4(iens)=BTR(4);
BTUV=double(typecast(tbytes(stind+[25:32]), 'int16'));
btdata.v1(iens)=BTUV(1);
btdata.v2(iens)=BTUV(2);
btdata.v3(iens)=BTUV(3);
btdata.v4(iens)=BTUV(4);

btdata.v3(iens)=BTUV(3);
btdata.v4(iens)=BTUV(4);



btdata.lat(iens)=nan;
btdata.lon(iens)=nan;

BCORR=tbytes(stind+[33:36]);
BPG=tbytes(stind+[41:44]);
%[BTR BTUV BCORR BPG]



end

function read_vmdasnav(tbytes,idt)
global offsets iens navdata
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);


UTCdd=double(tbytes(stind+[3]));
UTCmm=double(tbytes(stind+[4]));
UTCyy=double(typecast(tbytes(stind+[5:6]), 'uint16'));
UTCfirst=double(typecast(tbytes(stind+[7:10]), 'uint32')/10000.0);
navdata.toff(iens)=typecast(tbytes(stind+[11:14]), 'int32');
navdata.time(iens)=datenum(UTCyy,UTCmm,UTCdd,0,0,0)+(UTCfirst/(60*60*24));


bamcnv32=180.0/(2^31);
navdata.flat(iens)=double(typecast(tbytes(stind+[15:18]), 'int32'))*bamcnv32;
navdata.flon(iens)=double(typecast(tbytes(stind+[19:22]), 'int32'))*bamcnv32;
UTClast=typecast(tbytes(stind+[23:26]), 'uint32')/10000.0;
navdata.llat(iens)=double(typecast(tbytes(stind+[27:30]), 'int32'))*bamcnv32;
navdata.llon(iens)=double(typecast(tbytes(stind+[31:34]), 'int32'))*bamcnv32;
bamcnv16=180.0/(2^15);
navdata.spd(iens)=double(typecast(tbytes(stind+[35:36]), 'int16'));
navdata.dirtrue(iens)=double(typecast(tbytes(stind+[37:38]), 'uint16'))*bamcnv16;
navdata.dirmag(iens)=double(typecast(tbytes(stind+[39:40]), 'uint16'))*bamcnv16;
navdata.spdmg(iens)=double(typecast(tbytes(stind+[41:42]), 'uint16'));
navdata.dirmg(iens)=double(typecast(tbytes(stind+[43:44]), 'uint16'))*bamcnv16;
navdata.vtrue(iens)=double(typecast(tbytes(stind+[79:80]), 'int16'));
navdata.utrue(iens)=double(typecast(tbytes(stind+[81:82]), 'int16'));


end

function read_2022(tbytes,idt)
global offsets iens navdata
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
%mssg=char(tbytes(stind+1:stind+50));
% ID=double(tbytes(stind+[3:4]));
ID=double(typecast(tbytes(stind+[3:4]), 'uint16'));

if ID==104
    msize=double(typecast(tbytes(stind+[5:6]), 'int16'));
    dt=double(typecast(tbytes(stind+[7:14]), 'int64'));
    header=char(tbytes(stind+[15:21]));
    utctime=char(tbytes(stind+[22:31]));
    dlat=double(typecast(tbytes(stind+[32:39]),'double'));
    NS=char(tbytes(stind+[40:40]));
    if strcmp(NS,'S')
        dlat=-dlat;
    end
    navdata.lat(iens)=dlat;
    dlon=double(typecast(tbytes(stind+[41:48]),'double'));
    EW=char(tbytes(stind+[49:49]));
    if strcmp(EW,'W')
        dlon=-dlon;
    end
    navdata.lon(iens)=dlon;
end

end
function read_2100(tbytes,idt)
global offsets iens navdata
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);

mssg=char(tbytes(stind+1:stind+50));


end
function read_2101(tbytes,idt)
global offsets iens navdata
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);

mssg=char(tbytes(stind+[3:4]));
% disp(mssg')
end

function read_2102(tbytes,idt)
global offsets iens navdata
stind=offsets(idt);
id1=dec2hex(tbytes(stind+1),2);
id2=dec2hex(tbytes(stind+2),2);
mssg=char(tbytes(stind+1:stind+100));

end
function firstens=find_first_ensemble(fid)
global nbytes

firstens=0;
flag=1;
while flag
    chk=0;
    HID=fread(fid,1,'uint8');
    while ~strcmp(dec2hex(HID),'7F')
        HID=fread(fid,1,'uint8');
        firstens=firstens+1;
    end
    chk=chk+HID;
    HID=fread(fid,1,'uint8');
    chk=chk+HID;
    nbytes=fread(fid,1,'uint16');
    fseek(fid,-2,'cof');
    tbytes=fread(fid,abs(nbytes-2),'uint8');
    chk=chk+sum(tbytes);
    chksum=fread(fid,1,'uint16');
    chk1=mod(chk,65535)-floor(chk/65535);
    chk2=mod(chksum,65535);
    if chk1==chk2
        disp('Found First Ensemble')
        flag=0;
    end
    if flag
        firstens=firstens+2;
    end
    fseek(fid,-(abs(nbytes-2)+2),'cof');
end
end
