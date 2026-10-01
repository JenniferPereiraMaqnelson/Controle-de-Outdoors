# Controle de Outdoors – Implantação em Docker / Portainer

## O que este contêiner faz
Publica a aplicação web (`index.html`) em um servidor Nginx.
Nesta fase de transição, banco de dados, login (Microsoft Entra ID), imagens e
agendamento de alertas **continuam no Supabase**. O contêiner não guarda dados.

## Arquivos (raiz do repositório)
| Arquivo | Função |
|---|---|
| `index.html` | Aplicação, já configurada com o projeto Supabase |
| `Dockerfile` | Imagem `nginx:1.27-alpine` com a aplicação |
| `nginx.conf` | Configuração do servidor web (cache e cabeçalhos de segurança) |
| `docker-compose.yml` | Serviço `controle-outdoors`, porta 8085 do servidor → 80 do contêiner |

## Opção A – Stack pelo repositório (recomendada)
1. Portainer → **Stacks → Add stack** → nome `controle-outdoors`.
2. Build method **Repository**:
   - URL: `https://github.com/JenniferPereiraMaqnelson/Controle-de-Outdoors`
   - Reference: `refs/heads/main`
   - Compose path: `docker-compose.yml`
3. (Opcional) **GitOps updates** → Polling a cada 5 minutos.
4. **Deploy the stack**.

## Opção B – Linha de comando no servidor
```bash
git clone https://github.com/JenniferPereiraMaqnelson/Controle-de-Outdoors.git
cd Controle-de-Outdoors
docker compose up -d --build
```

## Requisitos obrigatórios
- **HTTPS**: o login Microsoft e o envio de imagens exigem conexão segura.
  Publicar atrás do proxy reverso com domínio e certificado
  (ex.: `https://outdoors.maqnelson.com.br` → `http://<servidor>:8085`).
- **Saída para a internet** a partir do navegador dos usuários:
  `*.supabase.co`, `login.microsoftonline.com`, `cdnjs.cloudflare.com`,
  `cdn.jsdelivr.net`, `fonts.googleapis.com`, `fonts.gstatic.com`,
  `*.tile.openstreetmap.org`.

## Após definir o endereço definitivo (responsável pela aplicação)
1. Supabase → Authentication → URL Configuration: incluir o novo endereço em
   **Redirect URLs** e atualizá-lo em **Site URL**.
2. Atualizar o link do cartão do Teams no `03_cartao_teams.sql` e reexecutá-lo.
3. Validar o login e, em seguida, desativar o GitHub Pages.
4. Nenhuma alteração é necessária no Microsoft Entra ID.
