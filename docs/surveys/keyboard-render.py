import json, math, itertools
B="/home/erikf/projects/3d/vial-qmk/keyboards/handwired/dactyl_manuform/5x6_64/"
rows=json.load(open(B+"keymaps/vial/vial.json"))["layouts"]["keymap"]
cur=dict(x=0,y=0,w=1,h=1,r=0,rx=0,ry=0); cl=dict(x=0,y=0); K=[]
for row in rows:
    if not isinstance(row,list): continue
    for item in row:
        if isinstance(item,str):
            K.append(dict(m=item,**{k:cur[k] for k in ('x','y','w','h','r','rx','ry')}))
            cur['x']+=cur['w']; cur['w']=cur['h']=1
        else:
            if 'r'  in item: cur['r']=item['r']
            if 'rx' in item: cur['rx']=cl['x']=item['rx']; cur['x']=cl['x']; cur['y']=cl['y']
            if 'ry' in item: cur['ry']=cl['y']=item['ry']; cur['x']=cl['x']; cur['y']=cl['y']
            if 'x'  in item: cur['x']+=item['x']
            if 'y'  in item: cur['y']+=item['y']
            if 'w'  in item: cur['w']=item['w']
            if 'h'  in item: cur['h']=item['h']
    cur['y']+=1; cur['x']=cur['rx']

GAP=0.059  # what KeyBoard.qml subtracts from the cap
def corners(k, gap):
    a=math.radians(k['r']); c,s=math.cos(a),math.sin(a)
    w,h=k['w']-gap,k['h']-gap
    pts=[(k['x'],k['y']),(k['x']+w,k['y']),(k['x']+w,k['y']+h),(k['x'],k['y']+h)]
    return [(k['rx']+(px-k['rx'])*c-(py-k['ry'])*s, k['ry']+(px-k['rx'])*s+(py-k['ry'])*c) for px,py in pts]

def overlap(A,B):  # SAT on two convex quads
    for P in (A,B):
        for i in range(len(P)):
            x1,y1=P[i]; x2,y2=P[(i+1)%len(P)]
            ax,ay=-(y2-y1),(x2-x1)
            pa=[ax*px+ay*py for px,py in A]; pb=[ax*px+ay*py for px,py in B]
            if max(pa)<=min(pb)+1e-9 or max(pb)<=min(pa)+1e-9: return False
    return True

print("keys:", len(K))
polys=[corners(k,GAP) for k in K]
bad=[(K[i]['m'],K[j]['m']) for i,j in itertools.combinations(range(len(K)),2) if overlap(polys[i],polys[j])]
print("overlapping cap pairs (drawn geometry):", len(bad), bad[:6])
# unrotated, to show why rotation is mandatory
flat=[corners(dict(k,r=0),GAP) for k in K]
fbad=[(K[i]['m'],K[j]['m']) for i,j in itertools.combinations(range(len(K)),2) if overlap(flat[i],flat[j])]
print("overlapping if rotation ignored:", len(fbad), fbad[:6])
xs=[p[0] for q in [corners(k,0) for k in K] for p in q]; ys=[p[1] for q in [corners(k,0) for k in K] for p in q]
print("bounds units: x %.3f..%.3f w=%.3f   y %.3f..%.3f h=%.3f"%(min(xs),max(xs),max(xs)-min(xs),min(ys),max(ys),max(ys)-min(ys)))
for u in (46,):
    print("at unit=%d px -> board %.1f x %.1f"%(u,(max(xs)-min(xs))*u,(max(ys)-min(ys))*u))
print("rotated clusters:", sorted({(k['r'],k['rx'],k['ry']) for k in K if k['r']}))
# min centre-to-centre distance, sanity
cent=[(sum(p[0] for p in q)/4, sum(p[1] for p in q)/4) for q in polys]
mind=min(math.dist(cent[i],cent[j]) for i,j in itertools.combinations(range(len(K)),2))
print("min centre-to-centre: %.4f u"%mind)
