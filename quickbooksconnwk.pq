// This file contains your Data Connector logic
[Version = "1.0.0"]
section quickbooksconnwk;

client_id = Text.FromBinary(Extension.Contents("client_id.txt"));
client_secret = Text.FromBinary(Extension.Contents("client_secret.txt"));
redirect_uri = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth = 1200;
windowHeight = 1000;

StartLogin = (resourceUrl, state, display) =>
      
        let
            client_id = client_id,
            client_secret = client_secret,
            redirect_uri = redirect_uri,
            AuthorizeUrl = "https://appcenter.intuit.com/connect/oauth2?" & Uri.BuildQueryString([
                client_id = client_id,
                client_secret = client_secret,
                scope = "com.intuit.quickbooks.accounting",
                state = "willy",
                response_type="code",
                redirect_uri = redirect_uri
                ])
        in
            [
                LoginUri = AuthorizeUrl,
                CallbackUri = redirect_uri,
                WindowHeight = windowHeight,
                WindowWidth = windowWidth,
                Context = null
            ];

FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]      
    in 
        TokenMethod(Parts[code], Parts[realmId]);

TokenMethod = (code, company_id) =>
    let       
        client_id = client_id,
        client_secret = client_secret,
        identifier = client_id & ":" & client_secret,
        Bytes = Text.ToBinary(identifier),
        Credentials = Binary.ToText(Bytes, BinaryEncoding.Base64),
        redirect_uri = redirect_uri,
        Response = Web.Contents("https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer", [
            Content = Text.ToBinary(Uri.BuildQueryString([           
                grant_type = "authorization_code",
                code = code,
                redirect_uri = redirect_uri])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json",
            #"Authorization" = "Basic " & Credentials]]),
        Parts = Json.Document(Response),
        Parts1 = Record.AddField(Parts, "realmId", company_id)
                           
    in
        Parts1;

[DataSource.Kind="quickbooksconnwk", Publish="quickbooksconnwk.Publish"]
shared quickbooksconnwk.Contents = () =>
let
headers = [
#"Authorization" = "Bearer " & Record.Field(Extension.CurrentCredential(),"access_token"),
Accept = "application/json;"],
company_id = Record.Field(Record.Field(Extension.CurrentCredential(), "Properties"),"realmId"),
response = Web.Contents("https://sandbox-quickbooks.api.intuit.com" & "/v3/company/" & company_id & "/account/1?minorversion=14",
[Headers=headers] ),
account = Record.Field(Json.Document(response), "Account")

in
account;
/*shared quickbooksconnwk.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        
        a = Table.FromValue(Record.Field(Extension.CurrentCredential(), "Properties"))
        
    in
        a;*/

// Data Source Kind description
quickbooksconnwk = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        // Anonymous = []
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin
        ]
    ]
];

// Data Source UI publishing description
quickbooksconnwk.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = quickbooksconnwk.Icons,
    SourceTypeImage = quickbooksconnwk.Icons
];

quickbooksconnwk.Icons = [
    Icon16 = { Extension.Contents("quickbooksconnwk16.png"), Extension.Contents("quickbooksconnwk20.png"), Extension.Contents("quickbooksconnwk24.png"), Extension.Contents("quickbooksconnwk32.png") },
    Icon32 = { Extension.Contents("quickbooksconnwk32.png"), Extension.Contents("quickbooksconnwk40.png"), Extension.Contents("quickbooksconnwk48.png"), Extension.Contents("quickbooksconnwk64.png") }
];
