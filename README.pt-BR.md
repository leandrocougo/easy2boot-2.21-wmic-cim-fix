# Easy2Boot 2.21 — correção de WMIC com PowerShell CIM

[English](README.md)

Patch comunitário não oficial para substituir consultas de disco feitas com WMIC por `Get-CimInstance`, mantendo os formatos de texto interpretados pelos scripts Batch originais.

**Esta é a revisão R2, confirmada como funcional pelo usuário que relatou o problema.** Ela também remove `-WindowStyle Hidden`, opção que pode ocultar o console compartilhado do CMD e dar a impressão de que a janela fechou. Essa confirmação individual não representa teste de todos os discos ou ambientes.

## Instalação

1. Feche as execuções do Easy2Boot. Extraia o Easy2Boot 2.21 em uma pasta própria.
2. Extraia este repositório em outra pasta e abra o Windows PowerShell nela.
3. Confira a operação sem alterar arquivos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Apply-Patch.ps1 -Easy2BootPath "C:\Tools\Easy2Boot_v2.21" -WhatIf
```

4. Aplique:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Apply-Patch.ps1 -Easy2BootPath "C:\Tools\Easy2Boot_v2.21"
```

Ajuste o caminho para a pasta que contém `menu.lst` e `_ISO`. `ExecutionPolicy Bypass` vale somente para esse processo PowerShell.

O aplicador verifica todos os hashes antes de substituir arquivos. Aceita os scripts originais conhecidos desta versão, a revisão R1 ou os arquivos já atualizados para R2. Se houver arquivo desconhecido ou modificado localmente, interrompe antes de alterar qualquer arquivo. Cria backup em `.e2b-cim-backup-<data>-<id>`, confere as cópias e tenta restaurar o backup se ocorrer falha durante a substituição. É necessário ter permissão de escrita na pasta de destino.

**Aplicar o patch apenas copia scripts.** Não inicia o Easy2Boot, não escolhe discos e não formata unidades.

5. Na pasta corrigida do Easy2Boot, execute **`INICIAR_COM_DIAGNOSTICO.cmd` como administrador**. O iniciador abre o processo interativo original, mantém a janela aberta ao terminar e registra stderr e o código de saída em `Easy2Boot-erro.log`. A criação do USB pode apagar o disco escolhido: confira o número antes de confirmar.

## O que está incluído

- `scripts/`: os nove scripts corrigidos completos, com os caminhos originais, e o iniciador de diagnóstico.
- `Apply-Patch.ps1`: aplicação com verificação de hashes e backup.
- `patches/easy2boot-2.21-cim-r2.patch`: todas as alterações em diff unificado.
- `manifest.json`: hashes SHA-256 dos arquivos originais, R1 e R2 e do instalador usado como base.
- `CHANGELOG.md` e `VALIDATION.md`: alterações e testes realizados.

Para copiar manualmente, faça backup e sobreponha o **conteúdo** de `scripts/` à raiz da extração do Easy2Boot, mesclando `_ISO`. Não substitua toda a pasta `_ISO` por uma pasta incompleta. A cópia manual não faz as verificações do aplicador.

## Escopo

Foram examinados 109 scripts CMD/BAT/VBS, com nove arquivos modificados e 22 chamadas de consulta migradas. Além das consultas de disco, foram migradas consultas de versão/build do Windows e os diagnósticos SecurityCenter2 do script principal.

As saídas são texto explícito: `propriedade=valor`, identificadores de discos, letras e associações `Disk #N, Partition #M`. Assim, os consumidores `FOR /F` e `FIND` mantêm seus formatos esperados. Não se usa `Format-Table` para produzir dados.

Requer Windows PowerShell com `Get-CimInstance` e acesso aos provedores CIM/WMI. O cenário validado é Windows 11; Windows antigos e WinPE não foram validados. A seleção de discos, confirmações, verificação de setores e lógica de formatação existentes foram mantidas.

Os executáveis não foram modificados nem incluídos. Permanecem fora do escopo as consultas auxiliares WMIC de inventário/licenciamento, o exemplo de renomeação de computador e o utilitário opcional Add WMIC. O pacote inteiro não é declarado livre de WMIC.

Base utilizada: `Easy2Boot_v2.21.exe`, SHA-256:

```text
bdd5ed526e0e9ae8550b331398c3e9dcd7c41cdc42616c07160f19ac3dd0966a
```

O nome da versão sozinho não garante arquivos idênticos; por isso o aplicador confere os hashes individuais.

## Desfazer

Feche o Easy2Boot. Copie a árvore de scripts salva dentro da pasta de backup de volta à raiz da extração, mantendo os caminhos. Não copie `backup-manifest.json`, que é somente metadado. Remova o iniciador de diagnóstico apenas se ele não existia antes; o manifesto do backup informa isso. Se o patch foi aplicado sobre R1, o backup restaura R1.

## Créditos

Correção independente da comunidade, sem vínculo oficial com o Easy2Boot. Os avisos existentes nos scripts originais foram preservados. Este pacote não atribui uma nova licença aos scripts upstream e não inclui um arquivo de licença upstream.
