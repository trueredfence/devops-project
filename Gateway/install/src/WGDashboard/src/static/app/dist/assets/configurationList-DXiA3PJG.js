import{_ as x,D as L,g as N,a,c as l,d as i,w as m,b as t,n as C,t as r,f,i as c,e as h,m as P,v as D,u as B,j as d,W as U,k as G,F as V,h as I}from"./index-glbWjskj.js";import{L as w}from"./localeText-CS3fF34S.js";const _={name:"configurationCard",components:{LocaleText:w},props:{c:{Name:String,Status:Boolean,PublicKey:String,PrivateKey:String},delay:String},data(){return{configurationToggling:!1}},setup(){return{dashboardConfigurationStore:L()}},methods:{toggle(){this.configurationToggling=!0,N("/api/toggleWireguardConfiguration/",{configurationName:this.c.Name},s=>{s.status?this.dashboardConfigurationStore.newMessage("Server",`${this.c.Name} ${s.data?"is on":"is off"}`):this.dashboardConfigurationStore.newMessage("Server",s.message,"danger"),this.c.Status=s.data,this.configurationToggling=!1})}}},y=()=>{B(s=>({"1d5189b2":s.delay}))},S=_.setup;_.setup=S?(s,o)=>(y(),S(s,o)):y;const K={class:"card conf_card rounded-3 shadow text-decoration-none"},R={class:"mb-0"},F={class:"card-title mb-0"},W={class:"card-footer d-flex gap-2 flex-column"},O={class:"row"},M={class:"col-6 col-md-3"},j={class:"text-primary-emphasis col-6 col-md-3"},z={class:"text-success-emphasis col-6 col-md-3"},E={class:"text-md-end col-6 col-md-3"},Y={class:"d-flex align-items-center gap-2"},q={class:"text-muted"},A={style:{"word-break":"keep-all"}},H={class:"mb-0 d-block d-lg-inline-block"},J={style:{"line-break":"anywhere"}},Q={class:"form-check form-switch ms-auto"},X=["for"],Z={key:4,class:"spinner-border spinner-border-sm ms-2","aria-hidden":"true"},$=["disabled","id"];function tt(s,o,e,v,k,p){const u=d("RouterLink"),n=d("LocaleText");return a(),l("div",K,[i(u,{to:"/configuration/"+e.c.Name+"/peers",class:"card-body d-flex align-items-center gap-3 flex-wrap text-decoration-none"},{default:m(()=>[t("h6",R,[t("span",{class:C(["dot",{active:e.c.Status}])},null,2)]),t("h6",F,[t("samp",null,r(e.c.Name),1)]),o[2]||(o[2]=t("h6",{class:"mb-0 ms-auto"},[t("i",{class:"bi bi-chevron-right"})],-1))]),_:1},8,["to"]),t("div",W,[t("div",O,[t("small",M,[o[3]||(o[3]=t("i",{class:"bi bi-arrow-down-up me-2"},null,-1)),f(r(e.c.DataUsage.Total>0?e.c.DataUsage.Total.toFixed(4):0)+" GB ",1)]),t("small",j,[o[4]||(o[4]=t("i",{class:"bi bi-arrow-down me-2"},null,-1)),f(r(e.c.DataUsage.Receive>0?e.c.DataUsage.Receive.toFixed(4):0)+" GB ",1)]),t("small",z,[o[5]||(o[5]=t("i",{class:"bi bi-arrow-up me-2"},null,-1)),f(r(e.c.DataUsage.Sent>0?e.c.DataUsage.Sent.toFixed(4):0)+" GB ",1)]),t("small",E,[t("span",{class:C(["dot me-2",{active:e.c.ConnectedPeers>0}])},null,2),f(" "+r(e.c.ConnectedPeers)+" / "+r(e.c.TotalPeers)+" ",1),i(n,{t:"Peers"})])]),t("div",Y,[t("small",q,[t("strong",A,[i(n,{t:"Public Key"})])]),t("small",H,[t("samp",J,r(e.c.PublicKey),1)]),t("div",Q,[t("label",{class:"form-check-label",style:{cursor:"pointer"},for:"switch"+e.c.PrivateKey},[!e.c.Status&&this.configurationToggling?(a(),c(n,{key:0,t:"Turning Off..."})):e.c.Status&&this.configurationToggling?(a(),c(n,{key:1,t:"Turning On..."})):e.c.Status&&!this.configurationToggling?(a(),c(n,{key:2,t:"On"})):!e.c.Status&&!this.configurationToggling?(a(),c(n,{key:3,t:"Off"})):h("",!0),this.configurationToggling?(a(),l("span",Z)):h("",!0)],8,X),P(t("input",{class:"form-check-input",style:{cursor:"pointer"},disabled:this.configurationToggling,type:"checkbox",role:"switch",id:"switch"+e.c.PrivateKey,onChange:o[0]||(o[0]=g=>this.toggle()),"onUpdate:modelValue":o[1]||(o[1]=g=>e.c.Status=g)},null,40,$),[[D,e.c.Status]])])])])])}const et=x(_,[["render",tt],["__scopeId","data-v-a85a04a5"]]),ot={name:"configurationList",components:{LocaleText:w,ConfigurationCard:et},async setup(){return{wireguardConfigurationsStore:U()}},data(){return{configurationLoaded:!1}},async mounted(){await this.wireguardConfigurationsStore.getConfigurations(),this.configurationLoaded=!0,this.wireguardConfigurationsStore.ConfigurationListInterval=setInterval(()=>{this.wireguardConfigurationsStore.getConfigurations()},1e4)},beforeUnmount(){clearInterval(this.wireguardConfigurationsStore.ConfigurationListInterval)}},st={class:"mt-md-5 mt-3"},at={class:"container-md"},nt={class:"d-flex mb-4 configurationListTitle align-items-center gap-3"},it={class:"text-body d-flex"},rt={class:"text-muted",key:"noConfiguration"};function ct(s,o,e,v,k,p){const u=d("LocaleText"),n=d("RouterLink"),g=d("ConfigurationCard");return a(),l("div",st,[t("div",at,[t("div",nt,[t("h2",it,[t("span",null,[i(u,{t:"WireGuard Configurations"})])]),i(n,{to:"/new_configuration",class:"btn btn-dark btn-brand rounded-3 p-2 shadow ms-auto rounded-3"},{default:m(()=>o[0]||(o[0]=[t("h2",{class:"mb-0",style:{"line-height":"0"}},[t("i",{class:"bi bi-plus-circle"})],-1)])),_:1}),i(n,{to:"/restore_configuration",class:"btn btn-dark btn-brand p-2 shadow ms-2",style:{"border-radius":"100%"}},{default:m(()=>o[1]||(o[1]=[t("h2",{class:"mb-0",style:{"line-height":"0"}},[t("i",{class:"bi bi-clock-history"})],-1)])),_:1})]),i(G,{name:"fade",tag:"div",class:"d-flex flex-column gap-3 mb-4"},{default:m(()=>[this.configurationLoaded&&this.wireguardConfigurationsStore.Configurations.length===0?(a(),l("p",rt,[i(u,{t:"You don't have any WireGuard configurations yet. Please check the configuration folder or change it in Settings. By default the folder is /etc/wireguard."})])):this.configurationLoaded?(a(!0),l(V,{key:1},I(this.wireguardConfigurationsStore.Configurations,(b,T)=>(a(),c(g,{delay:T*.05+"s",key:b.Name,c:b},null,8,["delay","c"]))),128)):h("",!0)]),_:1})])])}const ut=x(ot,[["render",ct],["__scopeId","data-v-16b5ab33"]]);export{ut as default};
