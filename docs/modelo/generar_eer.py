"""Genera docs/modelo/nexa_eer.png/.svg (EER estilo MySQL Workbench).
Uso: python3 docs/modelo/generar_eer.py docs/modelo/nexa_eer.png   (requiere matplotlib)
Edita las tablas T y las relaciones si cambia el modelo."""
import sys
# (nombre, tipo, flags) flags: P=PK F=FK N=NOT NULL U=UNIQUE ; warn=n
T = {}
def tabla(nombre, color, cols, nota=None):
    T[nombre] = (color, cols, nota)

W = lambda n: n  # marker
tabla("usuario", "#4a7ebb", [
 ("id","ObjectId","PN",0),("email","VARCHAR","N",7),("password","VARCHAR","N",0),
 ("rol","ENUM(PASAJERO,CONDUCTOR,ADMIN)","N",11),("fecha_registro","DATETIME","",0),
 ("estado_validacion","ENUM(PENDIENTE,APROBADO,RECHAZADO)","N",0),
 ("reset_token","VARCHAR","",0),("reset_token_expira","DATETIME","",0)],
 "UQ (email, rol)")
tabla("pasajero", "#4a7ebb", [
 ("usuario_id","ObjectId","PFN",0),("nombre_completo","VARCHAR","",9),("telefono","VARCHAR","",9),
 ("xp_total","INT","N",8),("nivel","INT","N",8),("nivel_actualizado_en","DATETIME","",0),
 ("ultimo_viaje_en","DATETIME","",0)])
tabla("conductor", "#4a7ebb", [
 ("usuario_id","ObjectId","PFN",0),("nombre_y_apellido","VARCHAR","",9),("ntelefono","BIGINT","",9),
 ("licencia","INT","U","3,4"),("soat","BIGINT","U","2,3"),("tarjeta_de_propiedad","BIGINT","U","2,3"),
 ("xp_total","INT","N",8),("xp_90d","INT","N",8),("nivel","INT","N",8),("nivel_actualizado_en","DATETIME","",0)])
tabla("admin", "#4a7ebb", [("usuario_id","ObjectId","PFN",0),("config_notificaciones","JSON","",0)])
tabla("dia_nexa", "#4a7ebb", [("pasajero_id","ObjectId","PFN",0),("dia","ENUM(LUN..DOM)","PN",0)])
tabla("conductor_favorito", "#4a7ebb", [("pasajero_id","ObjectId","PFN",0),("conductor_id","ObjectId","PFN",0)],
 "Tabla intermedia N:M  pasajero ↔ conductor")
tabla("vehiculo", "#4a7ebb", [
 ("id","VARCHAR","PN",5),("conductor_id","ObjectId","F",1),("placa","VARCHAR","NU",0),
 ("marca","VARCHAR","",0),("modelo","VARCHAR","",0),("color","VARCHAR","",0),
 ("tecnomecanica_id","INT","",10),("activo","BOOLEAN","N",0),("fecha_registro","DATE","",0)])
tabla("servicio", "#2e8b57", [
 ("id","VARCHAR","PN",5),("pasajero_id","ObjectId","FN",8),("conductor_id","ObjectId","F",8),
 ("vehiculo_id","VARCHAR","F",0),("origen / destino","VARCHAR","",0),("distancia_km","DOUBLE","",0),
 ("origen_lat / lng, destino_lat / lng","DOUBLE","",0),
 ("fecha_hora, aceptado, inicio, fin","DATETIME","",0),
 ("tarifa","DECIMAL","",0),("metodo_pago","VARCHAR","",0),
 ("estado","ENUM(SOLICITADO..CANCELADO)","N",0),
 ("calificacion_pasajero / conductor","DOUBLE","",0),("comentarios_*","TEXT","",0),
 ("cancelado_por","VARCHAR","",0),("nivel_pasajero","INT","",0),("upgrade_solicitado","BOOLEAN","",0),
 ("xp_ganado_pasajero / conductor","INT","",8)])
tabla("desglose_tarifa", "#2e8b57", [
 ("servicio_id","VARCHAR","PFN",0),("tarifa_base, factor_dinamico, tarifa_bruta","DECIMAL","",0),
 ("tasa_servicio, descuento_dia_nexa","DECIMAL","",0),("ahorro_escudo, costo_upgrade, costo_beneficios","DECIMAL","",0),
 ("total_pasajero, cashback","DECIMAL","",0),("comision_pct, comision_monto","DECIMAL","",0),
 ("ganancia_conductor, ingreso_plataforma","DECIMAL","",0),("definitivo","BOOLEAN","",0),
 ("beneficios_aplicados","JSON","",0)])
tabla("xp_evento", "#c2762b", [
 ("id","VARCHAR","PN",0),("usuario_id","ObjectId","FN",0),("viaje_id","VARCHAR","FN",0),
 ("rol","ENUM","N",0),("xp","INT","N",0),("motivo","ENUM(VIAJE,AJUSTE_CALIFICACION)","N",0),
 ("nota","VARCHAR","",0),("aplicado","BOOLEAN","",0),("creado_en","DATETIME","",0)],
 "UQ (viaje_id, rol, motivo)")
tabla("beneficio_uso", "#c2762b", [
 ("id","VARCHAR","PN",0),("usuario_id","ObjectId","FN",0),("viaje_id","VARCHAR","F",0),
 ("tipo","ENUM(DIA_NEXA, ESCUDO_TARIFA, ...)","N",0),("fecha","DATE","",0)])
tabla("credito_nexa", "#c2762b", [
 ("id","VARCHAR","PN",0),("usuario_id","ObjectId","FN",0),("viaje_id","VARCHAR","F",0),
 ("monto","DECIMAL","",0),("restante","DECIMAL","",0),("creado_en","DATETIME","",0),("vence_en","DATETIME","",0)])
tabla("auditoria_verificacion", "#8a5fa8", [
 ("id","VARCHAR","PN",0),("conductor_email","VARCHAR","",6),("admin_email","VARCHAR","",6),
 ("accion","ENUM(VERIFICACION_AUTOMATICA..RECHAZADO)","N",0),("resultado, resultado_placa, resultado_documento","VARCHAR","",0),
 ("fuente, placa, documento_enmascarado","VARCHAR","",0),("motivo","VARCHAR","",0),("fecha","DATETIME","",0)])
tabla("nota_admin", "#8a5fa8", [
 ("id","ObjectId","PN",0),("titulo","VARCHAR","",0),("contenido","TEXT","",0),("fecha_creacion","DATETIME","",0)])
tabla("info_modelo_ml", "#8a5fa8", [
 ("id","VARCHAR","PN",0),("nombre_modelo","VARCHAR","",0),("fecha_entrenamiento","DATETIME","",0),
 ("arbol_decision_texto","TEXT","",0),("instancias_usadas","INT","",0),
 ("total_satisfactorios / insatisfactorios","INT","",0),("promedios","JSON","",0)])


import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, Polygon
T = {n:(c,[(a,b,f,0) for a,b,f,_ in cols],nota) for n,(c,cols,nota) in T.items()}
FS=9.5; RH=18; HH=26
fig = plt.figure(figsize=(30,17), dpi=100); ax = fig.add_axes([0,0,1,1]); 
ren = fig.canvas.get_renderer()
def tw(s, size=FS, weight="normal"):
    t = ax.text(0,0,s,fontsize=size,fontweight=weight); w=t.get_window_extent(ren).width; t.remove(); return w

def clean(n): return n
info = {}
def medir(n):
    color, cols, nota = T[n]
    wn = max(tw(c[0], weight="bold" if "P" in c[2] else "normal") for c in cols)
    wt = max(tw(c[1]+(" UQ" if "U" in c[2] else ""), FS-1) for c in cols)
    w = 55+wn+14+wt+14+14
    w = max(w, tw(n,12,"bold")+30)
    h = HH + RH*len(cols) + (RH if nota else 0)
    return w,h
for n in T: info[n]=list(medir(n))


def W(n): return info[n][0]
def H(n): return info[n][1]
M=130
col0=40
G12=270; G01=140; G23=170; G34=290
X1 = col0 + max(W("usuario"),W("nota_admin"),W("info_modelo_ml")) + G01
X2 = X1 + max(W("pasajero"),W("conductor"),W("admin"),W("auditoria_verificacion")) + G12
X3 = X2 + max(W("vehiculo"),W("dia_nexa"),W("conductor_favorito")) + G23
X4 = X3 + W("servicio") + G34
pos={}
pos["pasajero"]=(X1,M+50)
pos["conductor"]=(X1,pos["pasajero"][1]+H("pasajero")+120)
pos["auditoria_verificacion"]=(X1,pos["conductor"][1]+H("conductor")+80)
pos["admin"]=(X1,pos["auditoria_verificacion"][1]+H("auditoria_verificacion")+70)
pos["usuario"]=(col0,pos["conductor"][1]+110)
pos["info_modelo_ml"]=(col0,M+50)
pos["nota_admin"]=(col0,M+50+H("info_modelo_ml")+40)
pos["dia_nexa"]=(X2,M+30)
pos["conductor_favorito"]=(X2,pos["dia_nexa"][1]+H("dia_nexa")+50)
pos["vehiculo"]=(X2,pos["conductor_favorito"][1]+H("conductor_favorito")+130)
pos["servicio"]=(X3,M+90)
pos["desglose_tarifa"]=(X4,M+10)
pos["xp_evento"]=(X4,pos["desglose_tarifa"][1]+H("desglose_tarifa")+70)
pos["beneficio_uso"]=(X4,pos["xp_evento"][1]+H("xp_evento")+50)
pos["credito_nexa"]=(X4,pos["beneficio_uso"][1]+H("beneficio_uso")+50)
TOTW = X4 + max(W(n) for n in ("desglose_tarifa","xp_evento","beneficio_uso","credito_nexa"))+150
BOT = max(pos[n][1]+H(n) for n in pos)
LEGY = pos['vehiculo'][1]+H('vehiculo')+95
BOT = max(BOT, LEGY+255)
CORR = BOT+45          # corredor inferior
TOTH = CORR+60
ax.set_xlim(0,TOTW); ax.set_ylim(TOTH,0); ax.axis("off")
fig.set_size_inches(TOTW/100, TOTH/100)
def rowy(n, col):
    color, cols, nota = T[n]
    if col=="hdr": return pos[n][1]+HH/2
    for i,c in enumerate(cols):
        if c[0]==col: return pos[n][1]+HH+RH*i+RH/2
    raise KeyError((n,col))
def S(n, s, col="hdr", dx=0, dy=0):
    x,y=pos[n]; w,h=info[n]
    if s=="L": return (x, rowy(n,col)+dy)
    if s=="R": return (x+w, rowy(n,col)+dy)
    if s=="T": return (x+dx, y)
    if s=="B": return (x+dx, y+h)
# ---- dibujar tablas
for n,(color,cols,nota) in T.items():
    x,y=pos[n]; w,h=info[n]
    ax.add_patch(Rectangle((x+3,y+3),w,h,fc="#00000022",ec="none",zorder=1))
    ax.add_patch(Rectangle((x,y),w,h,fc="white",ec="#555555",lw=1.2,zorder=2))
    ax.add_patch(Rectangle((x,y),w,HH,fc=color,ec="#555555",lw=1.2,zorder=3))
    ax.text(x+12,y+HH/2,n,color="white",fontsize=12,fontweight="bold",va="center",zorder=4)
    for i,(nm,tp,fl,wr) in enumerate(cols):
        cy=y+HH+RH*i+RH/2
        pk="P" in fl; fk="F" in fl; nn="N" in fl or pk; uq="U" in fl
        if pk and fk:
            ax.text(x+5,cy,"PK",fontsize=7.5,color="#b8860b",fontweight="bold",va="center",zorder=4)
            ax.text(x+21,cy,"FK",fontsize=7.5,color="#c0392b",fontweight="bold",va="center",zorder=4)
        elif pk: ax.text(x+5,cy,"PK",fontsize=7.5,color="#b8860b",fontweight="bold",va="center",zorder=4)
        elif fk: ax.text(x+5,cy,"FK",fontsize=7.5,color="#c0392b",fontweight="bold",va="center",zorder=4)
        dx=x+46
        ax.add_patch(Polygon([[dx,cy-4],[dx+4,cy],[dx,cy+4],[dx-4,cy]],closed=True,fc="#1f4e8c" if nn else "white",ec="#1f4e8c",lw=1,zorder=4))
        ax.text(x+55,cy,nm,fontsize=FS,fontweight="bold" if pk else "normal",va="center",zorder=4)
        wn = max(tw(c[0], weight="bold" if "P" in c[2] else "normal") for c in cols)
        ax.text(x+55+wn+14,cy,tp+(" UQ" if uq else ""),fontsize=FS-1,color="#666666",va="center",zorder=4)
        if wr:
            ww=36
            ax.add_patch(Rectangle((x+w-ww-1,cy-RH/2+1),ww,RH-2,fc="#d9302c",ec="none",zorder=4))
            ax.text(x+w-1-ww/2,cy,str(wr),fontsize=8,color="white",fontweight="bold",ha="center",va="center",zorder=5)
    if nota:
        cy=y+HH+RH*len(cols)+RH/2
        ax.add_patch(Rectangle((x,cy-RH/2),w,RH,fc="#f1f1f1",ec="none",zorder=3))
        ax.text(x+8,cy,nota,fontsize=8.5,style="italic",color="#444444",va="center",zorder=4)

def simbolo(pt, d, kind, color):
    """pt: punto en el borde de la tabla; d: vector unitario hacia fuera (hacia la línea)."""
    x,y=pt; dx,dy=d; px,py=-dy,dx
    kw=dict(color=color,lw=1.6,zorder=6,solid_capstyle="butt")
    def line(a,b,c,e): ax.plot([a,c],[b,e],**kw)
    if kind in("crowodot","crowtee","crow"):
        bx,by=x+dx*16,y+dy*16
        for s in(-1,0,1): line(bx,by,x+px*7*s,y+py*7*s)
        if kind=="crowtee": line(bx+dx*5-px*7,by+dy*5-py*7,bx+dx*5+px*7,by+dy*5+py*7)
        if kind=="crowodot":
            cx,cy=x+dx*25,y+dy*25
            ax.add_patch(Circle((cx,cy),4.5,fc="white",ec=color,lw=1.6,zorder=7))
    elif kind in("teetee","teeodot"):
        for k in(9,15):
            if kind=="teeodot" and k==15: continue
            line(x+dx*k-px*7,y+dy*k-py*7,x+dx*k+px*7,y+dy*k+py*7)
        if kind=="teeodot":
            ax.add_patch(Circle((x+dx*20,y+dy*20),4.5,fc="white",ec=color,lw=1.6,zorder=7))
        else:
            pass
HEAD={"1":"teetee","0..1":"teeodot","0..N":"crowodot","1..N":"crowtee"}
TIPO_COLOR={"1:1":"#2e7d32","1:N":"#1f5fa8","N:M":"#7b3fa0"}
def dirv(a,b):
    dx,dy=b[0]-a[0],b[1]-a[1]; L=(dx*dx+dy*dy)**.5; return (dx/L,dy/L)
def card_txt(pt,d,txt,color):
    # numero de cardinalidad junto al extremo, por encima/izquierda de la linea
    x,y=pt; dx,dy=d; px,py=-dy,dx
    if abs(dx)>0: ox,oy=x+dx*20, y-13
    else: ox,oy=x+13, y+dy*22
    ax.text(ox,oy,txt,fontsize=11,fontweight="bold",color=color,ha="center",va="center",zorder=9,
            bbox=dict(fc="white",ec="none",pad=0.5))
def rel(pts, ident, cp, cc, tipo, verbo, lpos=None):
    color=TIPO_COLOR[tipo]
    st = "-" if ident else (0,(6,4))
    ax.plot([p[0] for p in pts],[p[1] for p in pts],color=color,lw=1.8,linestyle=st,zorder=5)
    d0=dirv(pts[0],pts[1]); d1=dirv(pts[-1],pts[-2])
    simbolo(pts[0],d0,HEAD[cp],color); simbolo(pts[-1],d1,HEAD[cc],color)
    a,b = ("1","N") if tipo=="N:M" else tipo.split(":")
    card_txt(pts[0],d0,a,color); card_txt(pts[-1],d1,b,color)
    seg=max(zip(pts,pts[1:]),key=lambda s:abs(s[0][0]-s[1][0])+abs(s[0][1]-s[1][1]))
    lp=lpos or ((seg[0][0]+seg[1][0])/2,(seg[0][1]+seg[1][1])/2)
    ax.text(lp[0],lp[1],f"{tipo}  {verbo}",fontsize=9,fontweight="bold",color="white",ha="center",va="center",zorder=9,
            bbox=dict(boxstyle="round,pad=0.3",fc=color,ec="none"))

g1 = X1+max(W("pasajero"),W("conductor"),W("admin"),W("auditoria_verificacion"))
g2 = X2+max(W("vehiculo"),W("dia_nexa"),W("conductor_favorito"))
c01 = lambda k: col0+W("usuario")+35*k
c12 = lambda k: g1+40*k
c23 = lambda k: g2+30*k
c34 = lambda k: X3+W("servicio")+30*k
def via(a,b,cx): return [a,(cx,a[1]),(cx,b[1]),b]
# usuario: especializacion 1:1 (cada linea sale de su propia fila y va por su propio canal)
for k,(t,f) in enumerate([("pasajero","id"),("conductor","email"),("admin","password")]):
    a=S("usuario","R",f); b=S(t,"L","usuario_id")
    rel(via(a,b,c01(k+1)),True,"1","0..1","1:1","es un",lpos=(c01(k+1),(a[1]+b[1])/2 if t!="pasajero" else b[1]+60))
# pasajero
rel(via(S("pasajero","R","usuario_id"),S("dia_nexa","L","pasajero_id"),c12(1)),True,"1","0..N","1:N","elige")
rel(via(S("pasajero","R","ultimo_viaje_en"),S("conductor_favorito","L","pasajero_id"),c12(2)),True,"1","0..N","N:M","favorito (vía tabla intermedia)")
rel(via(S("conductor","R","usuario_id"),S("conductor_favorito","L","conductor_id"),c12(3)),True,"1","0..N","N:M","favorito (vía tabla intermedia)")
rel(via(S("conductor","R","nivel"),S("vehiculo","L","conductor_id"),c12(4)),False,"1","0..N","1:N","posee")
vb = pos["vehiculo"][1]+H("vehiculo")+40
a=S("conductor","R","nivel_actualizado_en"); b=S("servicio","L","conductor_id")
rel([a,(c12(5),a[1]),(c12(5),vb),(c23(2),vb),(c23(2),b[1]),b],False,"0..1","0..N","1:N","atiende",lpos=((c12(5)+c23(2))/2,vb))
rel([S("conductor","B",dx=70),S("auditoria_verificacion","T",dx=70)],False,"1","0..N","1:N","es auditado")
top = M-25
rel([S("pasajero","T",dx=60),(X1+60,top),(X3+60,top),S("servicio","T",dx=60)],False,"1","0..N","1:N","solicita",lpos=(X2+W("dia_nexa")/2+150,top))
rel(via(S("vehiculo","R","id"),S("servicio","L","vehiculo_id"),c23(1)),False,"0..1","0..N","1:N","usado en",lpos=(c23(1),(S("vehiculo","R","id")[1]+S("servicio","L","vehiculo_id")[1])/2))
rel(via(S("servicio","R","id"),S("desglose_tarifa","L","servicio_id"),c34(1)),True,"1","1","1:1","tiene",lpos=(c34(1)+70,S("desglose_tarifa","L","servicio_id")[1]))
rel(via(S("servicio","R","estado"),S("xp_evento","L","viaje_id"),c34(2)),False,"1","0..N","1:N","genera",lpos=(c34(2),S("servicio","R","estado")[1]+40))
rel(via(S("servicio","R","tarifa"),S("beneficio_uso","L","viaje_id"),c34(3)),False,"0..1","0..N","1:N","origina",lpos=(c34(3),S("beneficio_uso","L","viaje_id")[1]-45))
rel(via(S("servicio","R","cancelado_por"),S("credito_nexa","L","viaje_id"),c34(4)),False,"1","0..N","1:N","origina",lpos=(c34(4),S("credito_nexa","L","viaje_id")[1]-45))
ub = S("usuario","B",dx=60)
R4 = X4+max(W(n) for n in ("xp_evento","beneficio_uso","credito_nexa"))
ch = lambda k: R4+40+30*k
for k,(t,lab) in enumerate([("xp_evento","acumula"),("beneficio_uso","consume"),("credito_nexa","recibe")][::-1]):
    cx=ch(k); ry=S(t,"R","usuario_id")[1]; yy=CORR+16*k-16
    rel([(ub[0]+30*(2-k),ub[1]),(ub[0]+30*(2-k),yy),(cx,yy),(cx,ry),S(t,"R","usuario_id")],False,"1","0..N","1:N",lab,lpos=(X2+300+k*330,yy))
# titulo y leyenda
ax.text(TOTW/2,28,"NEXA — Modelo Entidad-Relación (EER, notación MySQL Workbench)",fontsize=22,fontweight="bold",ha="center",va="center")
ax.text(TOTW/2,56,"Vista lógica normalizada de las colecciones MongoDB · rama Nexa_New_Arquitecture",fontsize=12,color="#555555",ha="center",va="center")
lx,ly=X2+10,LEGY
ax.add_patch(Rectangle((lx,ly),430,262,fc="#fbfbfb",ec="#555555",lw=1,zorder=2))
ax.text(lx+10,ly+16,"Leyenda",fontsize=11,fontweight="bold",va="center",zorder=4)
for i,(t,txt) in enumerate([("1:1","uno a uno"),("1:N","uno a muchos"),("N:M","muchos a muchos (tabla intermedia)")]):
    yy=ly+42+i*24
    ax.text(lx+30,yy,t,fontsize=9,fontweight="bold",color="white",ha="center",va="center",zorder=4,bbox=dict(boxstyle="round,pad=0.3",fc=TIPO_COLOR[t],ec="none"))
    ax.text(lx+85,yy,txt,fontsize=9.5,va="center",zorder=4)
items=[("PK","#b8860b","Clave primaria      FK = clave foránea"),("◆","#1f4e8c","NOT NULL     ◇ admite nulo"),
       ("——","#222","Identificadora (la FK es parte de la PK)"),("- - -","#222","No identificadora"),
       ("┤├  ┤o","#222","exactamente uno · cero o uno"),(">o   >┤","#222","cero o muchos · uno o muchos")]
for i,(a,c,b) in enumerate(items):
    yy=ly+42+(i+3)*24
    ax.text(lx+10,yy,a,fontsize=9.5,color=c,fontweight="bold",va="center",zorder=4)
    ax.text(lx+85,yy,b,fontsize=9.5,va="center",zorder=4)
fig.savefig(sys.argv[1],dpi=100)
fig.savefig(sys.argv[1].replace(".png",".svg"))
