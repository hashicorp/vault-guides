const notify = new Notify(document.querySelector('#notify'));

async function mainLoaded() {
  // Set up click event listeners for the logout button and the login button.
  document.getElementById('logoutButton').addEventListener('click', logout, false);
  document.getElementById('authButton').addEventListener('click', authButtonClick, false);

  // If there is a vaulToken and vaultTokenPolicies stored then show the user
  // as logged in otherwise show them the login form

  browser.storage.local.get([ 'vaultToken', 'vaultTokenPolicies' ])
    .then(authField => {
      if (authField.vaultToken != undefined && authField.vaultTokenPolicies != undefined) {
        showAsLoggedInWith(authField.vaultToken, authField.vaultTokenPolicies);
      } else {
        notify.info("No Vault token found. Please Login.")
        showVaultLoginForm();
      }
    })
    .catch(error => {
      notify.error(error);
    });
}

function showVaultLoginForm() {
  browser.storage.sync.get([ 'vaultAddress', 'username', 'vaultAuthMount' ]).then(authField => {
    if (authField.vaultAddress) {
      var vaultServer = document.getElementById('serverBox');
      vaultServer.value = authField.vaultAddress;
    }

    if (authField.username) {
      var login = document.getElementById('loginBox');
      login.value = authField.username;
    }

    if (authField.vaultAuthMount) {
      var vaultAuthMount = document.getElementById('authMount');
      vaultAuthMount.value = authField.vaultAuthMount;
    }

  }).catch(error => {
    notify.error(error);
  });
}

function showAsLoggedInWith(vaultToken, vaultTokenPolicies) {
  notify.clear();
  document.getElementById('loggedIn').style.display = 'block';
  document.getElementById('logout').style.display = 'block';
  document.getElementById('login').style.display = 'none';

  document.getElementById('vaultToken').value = vaultToken;
  document.getElementById('vaultPolicies').innerHTML = `Attached policies: <br />${vaultTokenPolicies.join('<br />')}`
}

async function logout() {
  document.getElementById('login').style.display = 'block';
  document.getElementById('logout').style.display = 'none';
  document.getElementById('loggedIn').style.display = 'none';
  notify.clear().success('logged out', { time: 2000, removeOption: false });
  await browser.storage.local.set({ vaultToken: null, vaultTokenPolicies: null });
}

// invoked after user clicks "login to vault" button, if all fields filled in,
// and URL passed regexp check.
async function authToVault(vaultServer, username, password, authMount) {

  var loginUrl = `${vaultServer}/v1/auth/${authMount}/login/${username}`;

  fetch(loginUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ 'password': password }),
  }).then(response => {
    return response.json()
  }).then( json => {
    const authinfo = json.auth;
    browser.storage.local.set({ 'vaultToken': authinfo.client_token });
    browser.storage.local.set({ 'vaultTokenPolicies': authinfo.policies });
    showAsLoggedInWith(authinfo.client_token, authinfo.policies);
  }).catch(error => {
    notify.error(`
      There was an error while calling<br>
      ${loginUrl}<br>
      Please check if your username, password and mountpoints are correct.
    `);
  })
}

async function authButtonClick() {
  notify.clear();

  // get inputs from form elements, server URL, login and password
  var vaultServer = document.getElementById('serverBox');
  var login = document.getElementById('loginBox');
  var authMount = document.getElementById('authMount');
  var pass = document.getElementById('passBox');

  if ((vaultServer.value.length > 0) && (login.value.length > 0) && (pass.value.length > 0)) {
    // if input fields are not empty, attempt authorization to specified vault server URL.
    await browser.storage.sync.set({ 'vaultAddress': vaultServer.value });
    await browser.storage.sync.set({ 'username': login.value });
    await browser.storage.sync.set({ 'vaultAuthMount': authMount.value });
    authToVault(vaultServer.value, login.value, pass.value, authMount.value);
  } else {
    notify.error('Bad input, must fill in all 3 fields.');
  }
}

document.addEventListener('DOMContentLoaded', mainLoaded, false);
