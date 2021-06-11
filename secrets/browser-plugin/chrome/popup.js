/* global browser Notify */

const notify = new Notify(document.querySelector('#notify'));
async function mainLoaded() {
  var currentUrlHost = await getUrlHostOfCurrentTab();

  var vaultToken = await getStoredVaultToken();
  var vaultServerAddress = (await browser.storage.sync.get('vaultAddress'))
    .vaultAddress;

  // Create a URL to the secrets path within the secrets engine for the host.
  var secretsUrl = `${vaultServerAddress}/v1/vaultpass/data/${currentUrlHost}`
  // GET the secrets at the url with the token and then send the results to
  // the `showSecrets` function.
  await getSecretsAtUrl(secretsUrl,vaultToken,showSecrets);
}

//
// Look at the current tab and return the only the host name of the url
//
// Example:
//   If the current tab's URL is:
//      'https://learn.hashicorp.com/tutorials/vault/kubernetes-minikube'
//   This function would return:
//      'learn.hashicorp.com'
//
async function getUrlHostOfCurrentTab() {
  var tabs = await browser.tabs.query({ active: true, currentWindow: true });
  for (let tabIndex = 0; tabIndex < tabs.length; tabIndex++) {
    var tab = tabs[tabIndex];
    if (tab.url) {
      // Find the first term after the protocol (e.g. 'http://') up to the
      //   next forward slash. Name the regex group 'baseurl'
      return tab.url.match(/.+:\/\/(?<baseurl>[^\/]+).+$/).groups.baseurl
      break;
    }
  }
}

// Returns the Vault Token stored in the local storage. Checks if it is
// correctly formed and notifies if it does not meet the criteria.
async function getStoredVaultToken() {
  var vaultToken = (await browser.storage.local.get('vaultToken')).vaultToken;
  if (!vaultToken || vaultToken.length === 0) {
    return notify.clear().info(
      `No Vault-Token information available.<br>
      Please use the <a href="/options.html" class="link">options page</a> to login.`,
      { removeOption: false }
    );
  }
  return vaultToken;
}

function showSecrets(secrets) {
  document.getElementById('resultList').innerHTML = `<br/>${secrets.join('<br/>')}`;
}

async function getSecretsAtUrl(secretsUrl, vaultToken, withSecrets) {
  fetch(secretsUrl, {
    method: 'GET',
    headers: {
      'X-Vault-Token': vaultToken,
      'Content-Type': 'application/json'
    },
  }).then(response => {
    // notify.info(`${secretsUrl} + ${response.status}`);
    return response.json();
  }).then(json => {
    withSecrets(Object.entries(json.data.data));
  }).catch(error => {
    // Catches response errors
    // Catches the error when the json does not have the data key
    notify.error(
      `Not able to read secrets at ${secretsUrl} <br/> ${error}`,
      { removeOption: true }
    );
    return {};
  });
};

document.addEventListener('DOMContentLoaded', mainLoaded, false);
