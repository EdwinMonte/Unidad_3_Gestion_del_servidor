"""Cliente IPP mínimo: envía documentos desde Windows a CUPS por TCP/631."""
import http.client, struct, json
from pathlib import Path
HOST='192.168.246.134'; URI=f'ipp://{HOST}:631/printers/U3_PDF'
def attr(tag,name,value):
    n=name.encode();v=value if isinstance(value,bytes) else value.encode()
    return bytes([tag])+struct.pack('!H',len(n))+n+struct.pack('!H',len(v))+v
def request(op,extra=b'',data=b''):
    attrs=attr(0x47,'attributes-charset','utf-8')+attr(0x48,'attributes-natural-language','en')+attr(0x45,'printer-uri',URI)+attr(0x42,'requesting-user-name','edwinmonte')
    body=struct.pack('!BBHI',1,1,op,1)+b'\x01'+attrs+extra+b'\x03'+data
    c=http.client.HTTPConnection(HOST,631,timeout=20)
    c.request('POST','/printers/U3_PDF',body,{'Content-Type':'application/ipp'})
    r=c.getresponse();payload=r.read();c.close()
    status=struct.unpack('!H',payload[2:4])[0] if len(payload)>=8 else -1
    if r.status!=200 or not 0<=status<0x100:raise RuntimeError(f'HTTP {r.status}, IPP {status:#x}: {payload!r}')
    values={};pos=8;last=''
    while pos<len(payload):
        tag=payload[pos];pos+=1
        if tag==3:break
        if tag<=0x0f:continue
        n=struct.unpack('!H',payload[pos:pos+2])[0];pos+=2
        name=payload[pos:pos+n].decode();pos+=n
        size=struct.unpack('!H',payload[pos:pos+2])[0];pos+=2
        value=payload[pos:pos+size];pos+=size
        if name:last=name
        values[last]=struct.unpack('!i',value)[0] if tag in (0x21,0x23) and len(value)==4 else value.decode(errors='replace')
    return values
jobs=[]
for title,priority,hold in [('Red_Windows_PDF',50,False),('Prioridad_baja',10,True),('Prioridad_alta',90,True)]:
    extra=attr(0x42,'job-name',title)+attr(0x49,'document-format','application/postscript')
    extra+=b'\x02'+attr(0x21,'job-priority',struct.pack('!i',priority))
    if hold:extra+=attr(0x44,'job-hold-until','indefinite')
    doc=('%!PS\n/Courier findfont 16 scalefont setfont\n72 720 moveto\n('+title+' - Unidad 3.3) show\nshowpage\n').encode()
    result=request(2,extra,doc)
    jobid=result['job-id']
    details=request(9,attr(0x21,'job-id',struct.pack('!i',jobid)))
    record={k:details.get(k) for k in ['job-id','job-name','job-priority','job-state','job-originating-user-name']}
    jobs.append(record);print(json.dumps(record,ensure_ascii=False))
(Path(__file__).resolve().parent/'jobs_ipp.json').write_text(json.dumps(jobs,indent=2),encoding='utf-8')
print('IPP_RED_VERIFICADO: documentos enviados desde Windows a Ubuntu por TCP/631.')
