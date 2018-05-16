---
title: Integração Rocket.Chat, Messenger Facebook e OTRS/Ligero
layout: post
author: ronaldo
permalink: /integração-rocket.chat,-messenger-facebook-e-otrs/ligero/
source-id: 1Pzy81PsWYIGSUMkalhYFzyfMS3w6TFXPy94aiNsiykQ
published: true
---
Manual de Instalação e Uso

Complemento Add Ons

**Integração com Rocket.Chat**

Armazena as conversas de um chat em um novo chamado ou em um chamado existente.

Permite que notificações do OTRS sejam enviadas em canais ou para usuários do Rocket.Chat

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_0.png)

A **Complemento **realiza a implantação das melhores práticas ITIL para o Gerenciamento de Serviços de TI através do Software Livre. Contamos com o apoio de profissionais altamente qualificados e certificados para atender os mais variados perfis e necessidades de clientes.

Com base na construção de bons relacionamentos e parcerias, o objetivo da Complemento é fazer parte das expectativas e do êxito das empresas que contam com ela.

Partilhamos com nossos clientes as melhores práticas de GSTI, suportadas pelo software livre, guiando-os aos melhores resultados!


Quer saber mais? Acesse **[www.complemento.net.b**r](http://www.complemento.net.br) ou entre em contato conosco pelo telefone **(+55) 11 2506-0180 **ou no e-mail **[contato@complemento.net.b**r](mailto:contato@complemento.net.br)**.**

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_1.png)**          **![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_2.png)** **

Acompanhe nossas novidades nas redes sociais!

**SUMÁRIO**

[[TOC]]

# 1. O que este Add On faz

## 1.1. Chat Gratuito para Ligero/OTRS

O Rocket.Chat é uma plataforma gratuíta de Chat e comunicação, extremamente poderosa, criada por brasileiros e que já possui visibilidade mundial. O Rocket.Chat é super flexível e se integra a dezenas de softwares e plataformas.

Uma de suas funcionalidades é o Livechat, que permite o atendimento de clientes através de um chat que é facilmente "embedável" em qualquer site. Ele permite também a organização das equipes de atendimento em departamentos e organizando a distribuição dos clientes nas mesmas.

Por isso, a Complemento criou uma integração com o Rocket.Chat, que permite a disponibilização do Livechat para os clientes de seu OTRS, bem como a integração do Livechat de seu website por exemplo com o OTRS.

A Complemento também desenvolve Chatbots para auto atendimento integrados ao OTRS e a outros sistemas de sua empresa. Entre em contato conosco para mais informações.

Após a instalação e configuração, seus clientes começam a enxergar o livechat ao acessar a interface Customer do OTRS:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_3.png)

Ao clicar na barra do Chat, o usuário poderá escolher (opcionalmente) o departamento com o qual deseja conversar:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_4.png)

Note que o nome do usuário e seu e-mail estão pré-preenchidos pelo sistema.

O usuário pode então iniciar um chat por texto ou mesmo uma vídeo-chamada, caso o administrador do sistema libere esta opção:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_5.png)

O usuário inicia então sua conversa com a área desejada:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_6.png)

O **atendente **por sua vez, é notificado sempre que um chat é alocado para ele ou ela:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_7.png)

Ele inicia então sua interação com o cliente:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_8.png)

Ao clicar no botão de informações do chat, o atendente verificar **informações do cliente**, **seu e-mail** e **toda a navegação dele desde a criação do chat:**

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_9.png)

Clicando no menu **Editar**, o atendente pode definir o "Tópico" do Chat, que será utilizado para a criação do Chamado e/ou do Assunto do Artigo no OTRS:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_10.png)

Se o atendente informar o número do chamado conforme acima, precedido do caracter #, fará com que o sistema crie um artigo para cada ticket definido nas Tags com a descrição deste chat, no momento em que o mesmo é encerrado.

Se não for informado nenhum chamado, o sistema então irá criar um novo ticket, de acordo com as configurações de mapeamento que veremos mais adiante nas parametrizações do sistema.

Finalmente, para encerrar o Chat, clique no botão "Fechar":

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_11.png)

Toda a descrição do Chat fica registrada como uma nota de um novo chamado ou dos chamados referenciados na TAG do Chat:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_12.png)

1. O "Tópico do Chat", no caso da criação de um novo chamado, se torna o título do Chat.

## 1.2. Notificações de chamados em um canal do Rocket.Chat

O Rocket.Chat possui a funcionalidade de criação de canais. Isto facilita muito a organização da comunicação de suas equipes e projetos. Você pode ter um canal por projeto, por equipe, ou por tema que desejar.

Podemos ter por exemplo um canal dedicado para a equipe de Service Desk "#servicedesk".

Podemos configurar para que as notificações do OTRS sejam facilmente entregues neste canal, tais como "Novo Chamado", “Prazo de Solução a expirar”, “Novo chamado VIP” e assim por diante.

Desta maneira, toda sua equipe que acompanha o canal fica sabendo imediatamente que há uma nova ocorrência para ser tratada. Veja um exemplo de uma notificação de novo chamado no canal #servicedesk da Complemento:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_13.png)

O Rocket.Chat sempre notifica quando há mensagens novas em seus canais, de forma sonora e com notificações na barra de tarefas:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_14.png)

# 2. Instalação e Configuração

## 2.1. Livechat

### 2.1.1. Configuração no OTRS

#### 2.1.1.1. Instalando o AddOn

Primeiramente, é necessário realizar a instalação do AddOn gratuitamente a partir do repositório Complemento.

Se você ainda não conhece nosso repositório de AddOns, acesse o link abaixo e faça o download para ter acesso a este e muitos outros addons gratuítos para OTRS:

[https://complemento.net.br/repositorio-de-addons-complemento/](https://complemento.net.br/repositorio-de-addons-complemento/)

Você também pode fazer o download diretamente no site do Ligero:

[https://ligero.online](https://ligero.online)

#### 2.1.1.2. Preparando e Configurando o Livechat no OTRS

Para habilitar o Livechat no OTRS, você deve primeiramente obter o código de configuração em sua instalação RocketChat.

Depois de ter habilitado o [Livechat em seu RocketChat](https://rocket.chat/docs/administrator-guides/livechat), acesse o menu de administração do Livechat:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_15.png)

Em seguida, acesse o menu Instalação e copie o código gerado pelo Rocket:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_16.png)

Agora, acesse a Administração do OTRS → Configuração do Sistema → RocketChat → Settings

Cole o código acima no campo "RocketChat::Code" e clique em “Atualizar”:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_17.png)

#### 2.1.1.3. Mapeamento para Criação de Chamados

Como já mencionamos anteriormente, caso não seja informado um número de chamado precedido do caracter "#", o sistema irá criar um novo chamado então para este Chat no momento de seu encerramento.

Por isto, é necessário realizar a configuração de mapeamento da integração. Para isto, acesse em seu OTRS Administração → Web Services → RocketChat.

A seguir, clique na operação "Chat" para acessar suas configurações:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_18.png)

Em seguida, clique em configurar no mapeamento XSLT:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_19.png)

Aqui você pode realizar o mapeamento dos atributos do chamado. Estamos utilizando o método de mapeamento XSLT do OTRS. Você pode encontrar mais informações sobre ele nestes links:

Vamos analisar o código padrão do mapeamento e entender algumas de suas possibilidades:

<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--

       Departmente field mapping to queue for new ticket creation

  -->

  <xsl:variable name="depto">

    <xsl:value-of select="//visitor/department" />

  </xsl:variable>

  <xsl:variable name="deptotrans">

    <xsl:choose>

      <xsl:when test="$depto=''">Raw</xsl:when>

      <xsl:when test="$depto='E7S7a5ysKaxKeEZ7Y'">Raw</xsl:when>

      <xsl:otherwise>Raw</xsl:otherwise>

    </xsl:choose>

  </xsl:variable>

<!--

  Copy all the elements

-->

  <xsl:template match="node() | @*">

    <xsl:copy>

      <xsl:apply-templates select="node() | @*" />

    </xsl:copy>

  </xsl:template>

<!--

  Add "Queue","Priority","State"... nodes for new ticket creation

  You can/have to make your adjustment here

-->

  <xsl:template match="RootElement">

       <xsl:copy>

           <NewTicket>

               <Queue>

                   <xsl:value-of select="$deptotrans" />

               </Queue>

               <State>new</State>

               <Lock>unlock</Lock>

               <Priority>3 normal</Priority>

               <OwnerID>1</OwnerID>

               <UserID>1</UserID>

           </NewTicket>

           <xsl:apply-templates select="@*|node()"/>

       </xsl:copy>

  </xsl:template>

  <xsl:template match="content" />

</xsl:stylesheet>

Destacamos dois trechos do código. Em vermelho, o mapeamento de Departamento → Filas. Em azul, os dados iniciais de criação do chamado (estado, prioridade etc).

Sobre o mapeamento de Departamentos → Filas, é importante destacar o procedimento para verificar o código da departamento no RocketChat. 'E7S7a5ysKaxKeEZ7Y' no exemplo acima.

Para saber o código do departamento, acesse o livechat como cliente, clique com o botão direito no campo de departamento e em seguida em "Inspecionar" (no Google Chrome):

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_20.png)

Uma tela com o código fonte será exibida. Expanda o elemento "select" para ver os departamentos e seus códigos:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_21.png)

### 2.1.2. Configuração no Rocket.Chat

Após ter configurado o Livechat em seu Rocket.Chat, seus departamentos e atendentes, é necessário realizar a integração do mesmo com o OTRS.

Para isso acesse no Rocket.Chat "Livechat → Integrações".

Em "URL do webhook", coloque o endereço do Web Service de seu OTRS:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_22.png)

A URL deverá conter o seguinte padrão:

[http://[SERVIDOR]/otrs/nph-genericinterface.pl/Webservice/RocketChat/?UserLogin=[USUARIO](http://[SERVIDOR]/otrs/nph-genericinterface.pl/Webservice/RocketChat/?UserLogin=[USUARIO) ATENDENTE]&Password=[SENHA]

Obs: Crie um atendente para uso da integração com Rocket.Chat. Ele deverá ter permissões para adicionar notas e criar chamados nas filas correspondentes aos departamentos.

### 2.1.3. Recomendações

Sugerimos a utilização tanto do Rocket quanto do OTRS com HTTPS. Se você ainda não sabe como criar e instalar um certificado, [recomendamos a utilização do CERTBOT](https://certbot.eff.org/).

É importante que o FQDN do Rocket.Chat e o OTRS estejam no mesmo domínio. Sem isso, a funcionalidade de definir automaticamente o nome de usuário e e-mail na tela do cliente não irá funcionar:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_23.png)

Caso seu Rocket esteja em um domínio completamente diferente, recomendamos que você realize a liberação de CORS em sua aplicação.

Se isso não resolver, recomendamos que você faça um proxy reverso no Apache/NGINX de seu OTRS, apontando para o Rocket.Chat. Veja um exemplo para Apache:

-----------------------------------------------------------------------

    ProxyPreserveHost Off

    SSLProxyEngine On

    SSLProxyVerify none

    SSLProxyCheckPeerCN off

    SSLProxyCheckPeerName off

    SSLProxyCheckPeerExpire off

  <Location /packages>

    Order allow,deny

    Allow from all

    ProxyPass https://[SERVIDOR]/packages

    ProxyPassReverse https://[SERVIDOR]/packages

  </Location>

  <Location /sounds>

    Order allow,deny

    Allow from all

    ProxyPass https://[SERVIDOR]/sounds

    ProxyPassReverse https://[SERVIDOR]/sounds

  </Location>

  <Location /sockjs>

    Order allow,deny

    Allow from all

    ProxyPass https://[SERVIDOR]/sockjs

    ProxyPassReverse https://[SERVIDOR]/sockjs

  </Location>

  <Location /_timesync>

    Order allow,deny

    Allow from all

    ProxyPass https://[SERVIDOR]/_timesync

    ProxyPassReverse https://[SERVIDOR]/_timesync

  </Location>

  <Location /images>

    Order allow,deny

    Allow from all

    ProxyPass https://[SERVIDOR]/images

    ProxyPassReverse https://[SERVIDOR]/images

  </Location>

  <Location /livechat>

    Order allow,deny

    Allow from all

    ProxyPass https://[SERVIDOR]/livechat

    ProxyPassReverse https://[SERVIDOR]/livechat

  </Location>

--------------

## 2.2. Notificações em canais e para usuários

### 2.2.1. Configuração no Rocket.Chat

Para permitir que o Rocket.Chat receba notificações do OTRS, é necessário criar uma integração via Webhook para cada canal que se deseja integrar.

Vamos imaginar a criação de uma notificação de novo chamado deve ser enviada para o canal "#servicedesk".

Acesse a Administração do Rocket.Chat → Integrações e clique em "Nova Integração":

### ![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_24.png)

Selecione "Incoming WebHook".

Defina os seguintes valores nas configurações:

Ativado: Sim

Nome: Fila Service Desk

Postar no Canal: #servicedesk

Postar como: ServiceDesk

Clique em Salvar Alterações no final da página.

Após salvar as alterações, um novo campo é habilitado, o Webhook URL.

Copie o valor desta URL, pois é com ela que você irá configurar as notificações no OTRS:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_25.png)

### 2.2.2. Configurando as notificações no OTRS

Acesse Administração → Notificações de Chamado → Adicionar Notificação

Para nosso exemplo, vamos criar uma notificação de novo chamado que será enviada para o canal #servicedesk.

Para isso, nomeie a notificação, em seguida escolha o evento TicketCreate. Em "Filtro de Chamado" selecione a fila Service Desk:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_26.png)

Em "Métodos de notificação", habilite Rocket.Chat e cole a URL do Webhook criada no Rocket.Chat no campo “Rocket.Chat Webhook URL”:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_27.png)

Crie o texto da notificação no idioma desejado:

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_28.png)

Importante: a sintaxe da notificação que é enviada ao Rocket.Chat é diferente de uma sintaxe de notificação enviada para outros métodos. No exemplo acima, note que a URL é colocada num formato Markdown.

Sendo assim, recomendamos a criação de notificações separadas para os diferentes métodos desejados.

Texto da Notificação acima:

<OTRS_CUSTOMER_REALNAME> (<OTRS_CUSTOMER_DATA_UserCustomerID>) escreveu:

<OTRS_CUSTOMER_BODY[5]>

[<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>](<OTRS_CONFIG_HttpType>://<OTRS_CONFIG_FQDN>/<OTRS_CONFIG_ScriptAlias>index.pl?Action=AgentTicketZoom;TicketID=<OTRS_TICKET_TicketID>)

Ainda não é Cliente de Suporte e gostaria de ajuda especializada para configurar este Addon, sugerir melhorias ou reportar algum bug?

![image alt text]({{ site.url }}/public/xHx8c4MiWrVf9ZHLWcQeaw_img_29.png)

A Complemento é responsável pela instalação deste AddOn somente para Clientes de Suporte. Clique no link e conheça nossos [Planos de Suporte.](http://complemento.net.br/planos-de-suporte-otrs/)

