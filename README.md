# myMONAN-MPASSIT-scripts

Suíte de scripts para automatizar a instalação, compilação e execução do **MPASSIT** adaptado ao **MONAN**, com pós-processamento paralelo das saídas do modelo.

> Este repositório consome o código-fonte do [MyMONAN-MPASSIT-puro](https://github.com/carlosrenatosouza2/MyMONAN-MPASSIT-puro), clonando-o e compilando-o automaticamente.

---

## Sumário

- [Sobre](#sobre)
- [Estrutura de diretórios](#estrutura-de-diretórios)
- [Scripts principais](#scripts-principais)
- [Namelists (`scripts/namelists/`)](#namelists-scriptsnamelists)
- [Como executar](#como-executar)
  - [Opção 1 — script único](#opção-1--script-único)
  - [Opção 2 — passo a passo manual](#opção-2--passo-a-passo-manual)
- [Saídas de dados](#saídas-de-dados)
- [Observações e limitações conhecidas](#observações-e-limitações-conhecidas)
- [Créditos](#créditos)

---

## Sobre

Esta suíte automatiza todo o fluxo de pós-processamento do MONAN com o MPASSIT: clonagem e compilação do código-fonte, preparação de namelists e submissão da execução paralela — de forma semelhante à suíte `scripts_CT-CT` já utilizada no fluxo do MONAN.

O MPASSIT processa **um arquivo de saída do modelo por execução**, mas, diferente do `convert_mpas`, faz isso **em paralelo**: várias instâncias são executadas simultaneamente dentro do mesmo nó, cada uma em sua própria pasta de trabalho.

---

## Estrutura de diretórios

A estrutura segue o padrão já utilizado nos `scripts_CT-CT`:

```
myMONAN-MPASSIT-scripts/
├── scripts/
│   ├── namelists/
│   │   ├── varlist_2d.OPER
│   │   ├── varlist_3d.OPER
│   │   ├── streams.atmosphere.TEMPLATE
│   │   └── namelist.input.TEMPLATE
│   ├── 0.run_all.bash
│   ├── 1.install_mpassit.bash
│   ├── 2.run_mpassit.bash
│   └── setenv_jaci_gnu.bash
├── sources/
├── datain/
├── dataout/
└── execs/
```

---

## Scripts principais

| Script | Função |
|---|---|
| `0.run_all.bash` | Reúne todos os passos (instalação, compilação e execução) em um único script |
| `1.install_mpassit.bash` | Clona o repositório do MONAN-MPASSIT (já preparado para pós-processar saídas do MONAN) e o compila. Ao final, o executável fica disponível em `execs/` |
| `2.run_mpassit.bash` | Executa o MPASSIT: verifica se todos os arquivos necessários estão disponíveis, prepara os que faltam e dispara o processamento |
| `setenv_jaci_gnu.bash` | Prepara o ambiente de compilação/execução (módulos, compilador, ESMF) e define os recursos computacionais a serem usados (número de cores por execução, fila, etc.) |

> Se as saídas do MONAN estiverem em um diretório diferente do padrão (`dataout/YYYYMMDDHH/Model`), informe o caminho correto na variável `MODELOUTPUTDIR` dentro de `2.run_mpassit.bash`.

---

## Namelists (`scripts/namelists/`)

**`varlist_2d.OPER`**
Lista de variáveis 2D a pós-processar, em duas colunas: o nome original da variável na saída do modelo e o nome que ela receberá no arquivo final. O sufixo `OPER` indica que é a lista de variáveis de interesse operacional — no futuro poderão existir outras listas para diferentes grupos de uso.

**`varlist_3d.OPER`**
Idem ao anterior, para variáveis 3D.

**`namelist.input.TEMPLATE`**
Template do namelist do MPASSIT. Algumas opções já estão fixas e ajustadas para o MONAN; os campos entre `#...#` são substituídos automaticamente pelos scripts em tempo de execução:

```fortran
&config
 grid_file_input_grid = "#INITFILE#"
 diag_file_input_grid = "#MODELFILE#"
 hist_file_input_grid = ""
 output_file          = "./monan-mpassit-output.nc"
 block_decomp_file    = "#GRAPHINFOFILE#"
 interp_diag          = .true.
 interp_hist          = .false.
 wrf_mod_vars         = .false.
 output_grads         = .true.
 esmf_log             = .true.
 target_grid_type     = 'lat-lon'
 is_regional          = .false.
 nx                   = #NLON#
 ny                   = #NLAT#
 stand_lon            = 0.0
/
```

**`streams.atmosphere.TEMPLATE`**
Namelist original do MONAN/MPAS, consultado pelos scripts para recuperar o intervalo de tempo em que as saídas do modelo foram escritas — mesma lógica usada nos scripts CD-CT.
- Se a suíte for usada em conjunto com os scripts CD-CT, este arquivo já estará disponível.
- Em uso isolado, o arquivo acompanha o repositório, mas é necessário garantir manualmente que o intervalo de horas configurado corresponda ao das saídas do modelo.

> ⚠️ **Ponto frágil conhecido:** essa dependência manual de sincronismo entre o `streams.atmosphere` e o intervalo real das saídas do modelo ainda não é validada automaticamente. Uma abordagem mais robusta está prevista para versões futuras.

---

## Como executar

### Opção 1 — script único

Ajuste as variáveis de entrada no topo do `0.run_all.bash`:

```bash
# Input variables:-----------------------------------------------------
github_link="https://github.com/monanadmin/MONAN-Model.git"
github_link_MPASSIT="https://github.com/carlosrenatosouza2/MyMONAN-MPASSIT-puro.git"
monan_branch=1.4.3-rc
convertmpas_branch=1.2.0
mpassit_branch="feature/mpassit-mod2scripts-80"
EXP=GFS
RES=1024002       # Opções: 40962=120km; 163842=60km; 655362=30km; 1024002=24km; 2621442=15km; 5898242=10km
YYYYMMDDHHi=2026012000
FCST=24
#----------------------------------------------------------------------
```

E execute:

```bash
./0.run_all.bash
```

### Opção 2 — passo a passo manual

**1. Instalar e compilar o MPASSIT:**

```bash
./1.install_mpassit.bash [github_link_MPASSIT] [mpassit_branch]

# Exemplo:
./1.install_mpassit.bash https://github.com/carlosrenatosouza2/MyMONAN-MPASSIT-puro.git feature/mpassit-mod2scripts-80
```

**2. Executar o pós-processamento:**

```bash
./2.run_mpassit.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
```

---

## Saídas de dados

Os arquivos pós-processados são gravados em:

```
myMONAN-MPASSIT-scripts/dataout/YYYYMMDDHH/Post
```

---

## Observações e limitações conhecidas

- O pós-processamento paralelo cria uma pasta de execução por arquivo de saída do modelo, seguindo o mesmo esquema já usado no `convert_mpas`, mas com execuções simultâneas dentro do mesmo nó.
- A sincronização do intervalo de saída do modelo com `streams.atmosphere.TEMPLATE` ainda depende de conferência manual (ver aviso acima).

---

## Créditos

- Código-fonte do MPASSIT adaptado: [MyMONAN-MPASSIT-puro](https://github.com/carlosrenatosouza2/MyMONAN-MPASSIT-puro), baseado no repositório original de [Larissa Reames](https://github.com/LarissaReames/MPASSIT)
- Scripts de automação e adaptação ao fluxo MONAN/Jaci: Carlos Renato Souza
