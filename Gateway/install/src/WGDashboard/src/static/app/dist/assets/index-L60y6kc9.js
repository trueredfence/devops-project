function f(e){return e.includes(":")?6:e.includes(".")?4:0}function b(e){const i=f(e);if(!i)throw new Error(`Invalid IP address: ${e}`);let n=0n,o=0n;const r=Object.create(null);if(i===4)for(const s of e.split(".").map(BigInt).reverse())n+=s*2n**o,o+=8n;else{if(e.includes(".")&&(r.ipv4mapped=!0,e=e.split(":").map(t=>{if(t.includes(".")){const[c,l,d,a]=t.split(".").map($=>Number($).toString(16).padStart(2,"0"));return`${c}${l}:${d}${a}`}else return t}).join(":")),e.includes("%")){let t;[,e,t]=/(.+)%(.+)/.exec(e)||[],r.scopeid=t}const s=e.split(":"),u=s.indexOf("");if(u!==-1)for(;s.length<8;)s.splice(u,0,"");for(const t of s.map(c=>BigInt(parseInt(c||"0",16))).reverse())n+=t*2n**o,o+=16n}return r.number=n,r.version=i,r}const p={4:32,6:128},I=e=>e.includes("/")?f(e):0;function m(e){const i=I(e),n=Object.create(null);if(i)n.cidr=e,n.version=i;else{const a=f(e);if(a)n.cidr=`${e}/${p[a]}`,n.version=a;else throw new Error(`Network is not a CIDR or IP: ${e}`)}const[o,r]=n.cidr.split("/");if(!/^[0-9]+$/.test(r))throw new Error(`Network is not a CIDR or IP: ${e}`);n.prefix=r,n.single=r===String(p[n.version]);const{number:s,version:u}=b(o),t=p[u],c=s.toString(2).padStart(t,"0"),l=Number(t-r),d=c.substring(0,t-l);return n.start=BigInt(`0b${d}${"0".repeat(l)}`),n.end=BigInt(`0b${d}${"1".repeat(l)}`),n}export{m as p};