const notify = new Notify(document.querySelector('#notify'));

async function mainLoaded() {
  // When the `logoutButton` is clicked then perform `logout` function.
  document.getElementById('logoutButton').addEventListener('click', logout, false);

  // When the authButton is clicked then perform `authButtonClick` function
  document.getElementById('authButton').addEventListener('click', authButtonClick, false);

  // Is the user logged in already?
  //   - Yes, if the Vault token, `vaultToken`, and its policies store a value
  //     in the browsers local storage.
  //   - No, if the Vault token its policies value is undefined.
  browser.storage.local.get([ 'vaultToken', 'vaultTokenPolicies' ])
    .then(authField => {
      if (authField.vaultToken != undefined && authField.vaultTokenPolicies != undefined) {
        showAsLoggedInWith(authField.vaultToken, authField.vaultTokenPolicies);
      } else {
        notify.info("No Vault token found. Please Login.")
        populateOptionsFields();
      }
    })
    .catch(error => {
      notify.error(error);
    });
}

async function logout() {
  document.getElementById('login').style.display = 'block';
  document.getElementById('logout').style.display = 'none';
  document.getElementById('loggedIn').style.display = 'none';
  notify.clear().success('logged out', { time: 2000, removeOption: false });
  await browser.storage.local.set({ vaultToken: null, vaultTokenPolicies: null });
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

function showAsLoggedInWith(vaultToken, vaultTokenPolicies) {
  notify.clear();
  document.getElementById('loggedIn').style.display = 'block';
  document.getElementById('logout').style.display = 'block';
  document.getElementById('login').style.display = 'none';

  document.getElementById('vaultToken').value = vaultToken;
  document.getElementById('vaultPolicies').innerHTML = `Attached policies: <br />${vaultTokenPolicies.join('<br />')}`
}

function populateOptionsFields() {
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

async function authToVault(vaultServer, username, password, authMount) {

  const authinfo = {
    client_token: 'STUB_TOKEN',
    policies: ['default', 'vault-pass'],
  }


  // TODO: authToVault
  //
  // 1. Create the authentication URL with the username
  // 2. Perform a fetch of the authenication URL
  //      - method: 'POST'
  //      - headers: 'Content-Type': 'application/json'
  //      - body: JSON.stringify the password.
  //
  // 3. With a successful response, read the body as JSON
  // 4. With an error, notify an error

  await browser.storage.local.set({ vaultToken: authinfo.client_token });
  await browser.storage.local.set({ vaultTokenPolicies: authinfo.policies });
  showAsLoggedInWith(authinfo.client_token, authinfo.policies);

}

document.addEventListener('DOMContentLoaded', mainLoaded, false);
