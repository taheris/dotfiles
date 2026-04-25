{ lib, pkgs, ... }:

let
  inherit (lib) optionalAttrs;
  inherit (pkgs.stdenv) isDarwin;
in
{
  programs.zsh.shellAliases = {
    # docker container
    dca = "docker container attach";
    dcc = "docker container commit";
    dccp = "docker container cp";
    dccr = "docker container create";
    dcd = "docker container diff";
    dcex = "docker container exec --interactive --tty";
    dcexr = "docker container exec --interactive --tty --user 0:0";
    dcexu = "docker container exec --interactive --tty --user \"$(id -u):$(id -g)\"";
    dcep = "docker container export";
    dci = "docker container inspect";
    dck = "docker container kill";
    dclg = "docker container logs";
    dclgf = "docker container logs --follow";
    dcl = "docker container ls";
    dcla = "docker container ls --all";
    dcpe = "docker container pause";
    dcp = "docker container port";
    dcpr = "docker container prune";
    dcrn = "docker container rename";
    dcrm = "docker container rm";
    dcrmv = "docker container rm --volumes";
    dcr = "docker container run --interactive --tty --rm";
    dcre = "dcr --entrypoint";
    dcreb = "dcr --entrypoint bash";
    dcres = "dcr --entrypoint sh";
    dcrnh = "dcr --net=host";
    dcrns = "dcr --privileged --pid=host justincormack/nsenter1";
    dcrr = "docker container run --interactive --tty --user 0:0";
    dcru = "$(printf 'docker container run --interactive --tty --user %s:%s' $(id -u) $(id -g))";
    dcst = "docker container start";
    dcsp = "docker container stop";
    dcsa = "docker container stats";
    dct = "docker container top";
    dcupe = "docker container unpause";
    dcup = "docker container update";
    dcw = "docker container wait";

    # docker compose
    dcm = "docker compose";
    dcmf = "docker compose --file";
    dcmb = "docker compose build";
    dcmc = "docker compose config";
    dcmcr = "docker compose create";
    dcmd = "docker compose down --timeout 0";
    dcmev = "docker compose events";
    dcmex = "docker compose exec";
    dcmim = "docker compose images";
    dcmk = "docker compose kill";
    dcmlg = "docker compose logs";
    dcmp = "docker compose ps";
    dcmpl = "docker compose pull";
    dcmps = "docker compose push";
    dcmrs = "docker compose restart --timeout 0";
    dcmrm = "docker compose rm";
    dcmrn = "docker compose run";
    dcmst = "docker compose start";
    dcmsp = "docker compose stop --timeout 0";
    dcmt = "docker compose top";
    dcmu = "docker compose up --timeout 0";

    # docker image
    dil = "docker image ls";
    dila = "docker image ls --all";
    dib = "docker image build --force-rm";
    dibt = "docker image build --force-rm --tag";
    dii = "docker image inspect";
    dih = "docker image history";
    diip = "docker image import";
    dild = "docker image load";
    dips = "docker image push";
    dipl = "docker image pull";
    dipr = "docker image prune";
    dipra = "docker image prune --all";
    dirm = "docker image rm";
    dis = "docker image save";
    dit = "docker image tag";

    # docker network
    dnc = "docker network create";
    dncn = "docker network connect";
    dndc = "docker network disconnect";
    dni = "docker network inspect";
    dnl = "docker network ls";
    dnpr = "docker network prune";
    dnrm = "docker network rm";

    # docker system
    dse = "docker system events";
    dsi = "docker system info";
    dsdf = "docker system df";
    dsdfv = "docker system df --verbose";
    dspr = "docker system prune";
    dspra = "docker system prune --all";
    dsprv = "docker system prune --volumes";
    dsprav = "docker system prune --all --volumes";

    # docker volume
    dv = "docker volume";
    dvc = "docker volume create";
    dvi = "docker volume inspect";
    dvl = "docker volume ls";
    dvpr = "docker volume prune";
    dvrm = "docker volume rm";

    # kubectl
    k = "kubectl";
    ka = "kubectl apply";
    kaf = "kubectl apply --filename";
    klg = "kubectl logs";
    klgf = "kubectl logs --follow";
    klgp = "kubectl logs --previous";
    kp = "kubectl proxy";
    kpf = "kubectl port-forward";
    kr = "kubectl run --rm --stdin --tty";
    kex = "kubectl exec --stdin --tty";

    # kubectl get
    kg = "kubectl get";
    kga = "kubectl get all";
    kgd = "kubectl get deployment";
    kgev = "kubectl get event";
    kgi = "kubectl get ingress";
    kgj = "kubectl get jobs";
    kgp = "kubectl get pods";
    kgpi = "kubectl get pods -o json | jq -r '.items | .[] | (.spec?.containers? | .[]? | .image?)' | sort --unique";
    kgn = "kubectl get nodes";
    kgcm = "kubectl get configmap";
    kgns = "kubectl get namespaces";
    kgpv = "kubectl get persistentvolumes";
    kgpvc = "kubectl get persistentvolumeclaims";
    kgrs = "kubectl get replicaset";
    kgsec = "kubectl get secret";
    kgsvc = "kubectl get service";
    kgss = "kubectl get statefulset";

    # kubectl describe
    kd = "kubectl describe";
    kda = "kubectl describe all";
    kdd = "kubectl describe deployment";
    kdi = "kubectl describe ingress";
    kdj = "kubectl describe jobs";
    kdp = "kubectl describe pods";
    kdn = "kubectl describe nodes";
    kdcm = "kubectl describe configmap";
    kdns = "kubectl describe namespaces";
    kdpv = "kubectl describe persistentvolumes";
    kdpvc = "kubectl describe persistentvolumeclaims";
    kdrs = "kubectl describe replicaset";
    kdsec = "kubectl describe secret";
    kdsvc = "kubectl describe service";
    kdss = "kubectl describe statefulset";

    # kubectl config
    kcv = "kubectl config view";
    kccc = "kubectl config current-context";
    kcdc = "kubectl config delete-context";
    kcdcl = "kubectl config delete-cluster";
    kcgc = "kubectl config get-contexts";
    kcgcl = "kubectl config get-clusters";
    kcrc = "kubectl config rename-context";
    kcs = "kubectl config set";
    kcsc = "kubectl config set-context";
    kcscc = "kubectl config set-context --current";
    kcsccns = "kubectl config set-context --current --namespace";
    kcscl = "kubectl config set-cluster";
    kcscr = "kubectl config set-credentials";
    kcu = "kubectl config unset";
    kcuc = "kubectl config use-context";
    kcucdd = "kubectl config use-context docker-desktop";
    kcucrd = "kubectl config use-context rancher-desktop";

    # kubectl edit
    ked = "kubectl edit";
    keda = "kubectl edit all";
    kedd = "kubectl edit deployment";
    kedi = "kubectl edit ingress";
    kedj = "kubectl edit jobs";
    kedp = "kubectl edit pods";
    kedn = "kubectl edit nodes";
    kedcm = "kubectl edit configmap";
    kedns = "kubectl edit namespaces";
    kedpv = "kubectl edit persistentvolumes";
    kedpvc = "kubectl edit persistentvolumeclaims";
    kedrs = "kubectl edit replicaset";
    kedsec = "kubectl edit secret";
    kedsvc = "kubectl edit service";
    kedss = "kubectl edit statefulset";

    # kubectl delete
    kdel = "kubectl delete";
    kdeld = "kubectl delete deployment";
    kdeli = "kubectl delete ingress";
    kdelj = "kubectl delete jobs";
    kdelp = "kubectl delete pods";
    kdeln = "kubectl delete nodes";
    kdelcm = "kubectl delete configmap";
    kdelns = "kubectl delete namespaces";
    kdelpv = "kubectl delete persistentvolumes";
    kdelpvc = "kubectl delete persistentvolumeclaims";
    kdelrs = "kubectl delete replicaset";
    kdelsec = "kubectl delete secret";
    kdelsvc = "kubectl delete service";
    kdelss = "kubectl delete statefulset";
  }

  # apple container — darwin only
  // optionalAttrs isDarwin {
    # apple container
    ac = "container";
    acb = "container build";
    accr = "container create";
    ack = "container kill";
    acl = "container list";
    acla = "container list --all";
    aclg = "container logs";
    acr = "container run";
    acrm = "container delete";
    acsa = "container stats";
    acsp = "container stop";
    acst = "container start";

    # apple container image
    aci = "container image";
    acii = "container image inspect";
    acil = "container image list";
    acild = "container image load";
    acipl = "container image pull";
    acipr = "container image prune";
    acirm = "container image delete";
    acis = "container image save";
    acitg = "container image tag";

    # apple container network
    acn = "container network";
    acncr = "container network create";
    acni = "container network inspect";
    acnl = "container network list";
    acnrm = "container network delete";

    # apple container system
    acs = "container system";
    acsd = "container system dns";
    acsdf = "container system df";
    acsk = "container system kernel";
    acslg = "container system logs";
    acss = "container system status";
    acssp = "container system stop";
    acsst = "container system start";

    # apple container volume
    acv = "container volume";
    acvcr = "container volume create";
    acvi = "container volume inspect";
    acvl = "container volume list";
    acvpr = "container volume prune";
    acvrm = "container volume delete";
  };
}
