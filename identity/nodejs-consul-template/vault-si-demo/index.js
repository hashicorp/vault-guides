/**
 * Copyright (c) HashiCorp, Inc.
 * SPDX-License-Identifier: MPL-2.0
 */

var express = require('express');
var app = express();
var config = require('./config')

app.get('/', function (req, res) {
  res.send('Your Vault secret is: ' + config.vault_secret);
});
app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});
