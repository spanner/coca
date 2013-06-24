# Coca

Coca stands for **Chain of Command Authentication**. It's a lightweight authentication-delegation scheme that makes SSO very easy to add to a devise-based rails app. Delegation is through an ordinary JSON API so you can pass any user data you like down the chain after authentication succeeds.

We thought about calling it 'delegated devise' because in the present implementation it's just a devise strategy that can delegate to another application and an API for receiving delegated auth calls. In future we'd like to extend the principle more widely so we gave it a more general name.

Coca is highly configurable but the defaults are simple and secure. It is designed to be part of a service-based architecture, where it will bind together a set of applications around a shared authentication service.

Coca is naturally extensible because you can send any information you like down the chain and do whatever you like when it arrives. RBAC or other authorization information is easily distributed this way.

Since we already have a nice tidy deference tree, Coca also supports attribute propagation. Your auth master is likely also to be a directory server and coca can help you to dry out contact (or any) attributes by passing notifications up and down the chain when they change.


## tl;dr

    class User < ActiveRecord::Base
      # must have a :uid column
      devise :cocable
    end
    
    # and in an initialiser:
    
    Coca.secret = "Shared secret key"
    
    Coca.delegate_to do |master|
      master.host = auth.example.com
    end


## Use coca if

* You want to implement single sign-on within a cluster of trusted applications that all inhabit a single domain;

* You want an easy way to pass around permissions or other extended user information;

* You want your authentication service to be part of your usual rails cluster and benefit from its existing availability and backup measures;

* You're not planning to offer a remote login-with-me service to applications as yet unknown.

There's nothing to stop you running coca in parallel with other auth services including OAuth, SAML or even LDAP.


## Usage

Each link in the chain of command is defined as a server to which we defer  and/or a set of servers from which we accept requests. Within that link you  also have to declare that one or models should take part in the authentication scheme.


### Configuring the chain

Each application can be master, servant or both. Configuration is usually in config/initialisers/coca.rb:

    # On every application in this chain
    
    Coca.secret = "Shared secret key"

    # To act as a servant:

    Coca.delegate_to do |master|
      master.host = fq.domain.com or ip address or localhost
      master.port = optional
      master.path = "/coca/user"
    end
    
    # To act as a master:
    
    Coca.delegate_from do |servant|
      servant.host = fq.domain.com or ip address or localhost
      servant.ttl = 3600
    end
    
You can have any number of links up and down. More than one `delegate_to` is unlikely but possible.
    
    # TTL can be set globally
    Coca.token_ttl = 86400
    
    # disable to not broadcast user changes or ignore incoming updates
    Coca.propagate_updates = true
    
    # disable to allow insecure requests in and out
    Coca.require_https = true
    
    # disable to omit reverse IP check on incoming requests and updates
    Coca.check_source = true

    # you may want to set this per environment
    Coca.cookie_name = 'must_be_the_same_across_sso_group'
    Coca.cookie_domain = :all


### Delegating in a model

To start with coca is implemented as a devise strategy. Minimally:

    class User < ActiveRecord::Base
      devise :cocable

You can try other strategies first: they will work in the usual way and check against local resource properties. The `:cocable` strategy would normally be last. 

    class User < ActiveRecord::Base
      devise :database_authenticatable,
             :token_authenticatable,
             :cocable

If masters are defined, the cocable strategy will pass credentials up the chain before finally admitting failure.


### Authenticating in the master

The delegated auth call is just an ordinary API request. The supplied auth parameters are passed on. If they are accepted by the master server then the API request will work and a JSON packet will be returned. If not, we return 401. All of this is done just by trying to authenticate the resource in the usual way, and usually requires no change to your resource class.

To continue the chain upward, just add the cocable strategy to the User class in your master application (and define a master). 


### Routing in the master

For most purposese you only need to mount coca:

    mount Coca::Engine => "/coca", :as => :coca

The main api controller response to /coca/authenticate. It's a very ordinary controller that inherits from your ApplicationController and tries to authenticate against your local resources.


### Data

Coca requires all your authenticable resources to have a `uid` column, and it expects your authentication master to set that value and pass it down on auth.

In the servant coca requires no devise columns. If you're not trying any other strategies locally, your user model can be very minimal.

In the master coca has no other requirements but you will want a fuller set of devise strategies, probably include `:database_authenticatable` and `:token_authenticatable` and all the data columns they require.


## Extending Coca

At heart coca is a simple remote authentication service: credentials are checked remotely and if they are found valid, user information is returned.

The data package that we return on successful auth is built by calling `serializable_hash` on the user model in the coca master. As a minimum it should return an auth token, but you can add any other data you like. If you have local resources that are owned by remote users, some kind of uid will be needed. Also permissions, friends lists, recent messages, password replacement instructions: anything it makes sense to hold centrally can be worked out in the master and passed down to all servant applications.

Your coca response package will be treated as model attributes. It's up to you to make sure that your local user object does the right thing with whatever is passed down.


## Reminders and confirmations

We're going to need some routing here. Only the auth master is in a position to handle password-reminders and to send confirmation and other messages to new users.


## Propagating resource changes

It's a short step from an auth server to a directory server. Once authentication is centralised, you start to avoid duplicating other user attributes. But what if you want to display the user's email address in one of the servant apps, or offer the user a change of address form while they're working in the calendar? You don't always want to send them somewhere else, or call another server just to get a single attribute.


## How coca works

All the actual authentication done by devise as usual. Coca just adds a way to try out credentials on another server. 

1. A coca servant app has its own devise strategies. You can set that up any way you like, and you may choose to accept credentials locally for some users.

2. If the app is presented with an auth token or login pair that it doesn't recognise, those credentials are passed up to the configured master application in a JSON request that includes a predefined API key. 

3. The master will check that the requesting host and the secret key match before it gives any response.

4. If the supplied credentials succeed in authenticating the user at the master application, it will return 200 and a package of user information. If the app doesn't recognise the credentials, it may pass them on to its own coca master. If there isn't one, or that request fails too, it will return 401 and no data.

5. As the confirmation package travels down the chain each servant app stores the auth token and does what it likes with any other data that is returned.

6. Subsequent requests that present a valid auth token will be successful at the bottom of the chain.

7. The master will include in the confirmation package a configurable TTL for the auth token. You can use this to set a balance between revokability and responsiveness. Set it to zero for maximum control or to a sensible session length like 30 minutes to minimise the coca overhead.

8. The original servant app receives the confirmation package, saves the authentication token and does whatever it does with the other data. It also puts the auth token in a domain cookie (not the usual session cookie) that will be picked up by any other application in the same domain.

9. When the same browser visits another application in the same domain, it presents the master's auth token cookie. The second servant app passes that token up the chain to the same master. Having issued the token, the master accepts it and returns the same confirmation package as before. The second servant stores the auth token locally so that it too can accept subsequent requests without delegation, token expiry permitting.


## Compared to OAuth

* **This is not an authorization service.** There is no mechanism for issuing API tokens or granting access to individual resources. The chain of command is defined on initialisation and all requests and responses have to come from sources that are already trusted. OAuth makes it possible to have ad-hoc relationships between strangers. Coca is a conversation among friends.

* **OAuth is a user-pull scheme** that bounces off the browser a few times and requires it to pass callbacks between servers. The user sees confirmation dialogs from different providers or is forced to visit services in a certain order. Coca works by server-pull, invisible to the user and no more difficult than just logging in. It doesn't matter where you arrive: once you've logged in, you're in.

* **Oauth works across domains.** Coca mostly doesn't: you can authenticate against a master at any address, but SSO is limited to domains that can share a cookie. In practice that means coca only provides SSO across related subdomains.

* **OAuth is horrible to work with,** absurdly complicated and a daft way to implement SSO unless you are also piggybacking on a remote service. Coca is quite nice.


## Compared to XAuth

* XAuth is just OAuth made stupider. It is superficially similar to coca in that credentials are passed to a remote server, but after that you're bouncing around callbacks again. 


## Compared to LDAP

There's nothing wrong with LDAP. If you're working in a situation where an LDAP server is available, and you don't need to layer RBAC or anything else on top, we advise you to use it.

If you don't already have an LDAP server with its own availability regime and a dedicated team of lab-coats, you get to choose between several lardy Java services. None of them will sit nicely on your load-balanced cloud node, and none of them are easy to couple with RBAC or other services. In that case you're probably better off using coca and providing a CardDAV service from the top of the chain.


## Author

William Ross for spanner. Will at spanner dot org.

## Copyright

Copyright Spanner 2013. All rights reserved.

## License

Released under the MIT license.

