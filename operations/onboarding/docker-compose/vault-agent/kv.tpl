{{ with secret "kv/data/nginx/static" -}}
<html><head>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/css/bootstrap.min.css" integrity="sha384-B0vP5xmATw1+K9KRQjQERJvTumQW0nPEzvF6L/Z6nronJ3oUOFUFpCjEUQouq2+l" crossorigin="anonymous">
</head><body>
<div class="alert alert-success" role="alert">
<h5 class="alert-heading">Secret path &#58; kv/data/nginx/static, Policy &#58; kv_rw_policy</h5>
    <li><strong>app</strong> &#58; {{ .Data.data.app }}</li>
    <li><strong>username</strong> &#58; {{ .Data.data.username }}</li>
    <li><strong>password</strong> &#58; {{ .Data.data.password }}</li></ul>
<hr><p class="mb-0">Helpful Vault commands</p>
<pre><code>
vault policy read kv_rw_policy
</code></pre></div> </body></html>
{{- end }}