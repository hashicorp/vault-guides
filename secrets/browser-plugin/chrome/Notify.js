class Notify {
  constructor(node) {
    this.node = node;
    this.messages = [];
  }

  /**
   * @param {String} message will be parsed to HTML
   * @param {Object} options 
   * @param {Boolean} [options.removeOption] wether or not to show the ✖
   * @param {Number} [options.time] when declared, notification will disappear after Xms
   * @returns this
   */
  error(message, options) {
    return this.message({ level: 'error', message, ...options });
  }

  /**
   * @param {String} message will be parsed to HTML
   * @param {Object} options 
   * @param {Boolean} [options.removeOption] wether or not to show the ✖
   * @param {Number} [options.time] when declared, notification will disappear after Xms
   * @returns this
   */
  success(message, options) {
    return this.message({ level: 'success', message, ...options });
  }

  /**
   * @param {String} message will be parsed to HTML
   * @param {Object} options 
   * @param {Boolean} [options.removeOption] wether or not to show the ✖
   * @param {Number} [options.time] when declared, notification will disappear after Xms
   * @returns this
   */
  info(message, options) {
    return this.message({ level: 'info', message, ...options });
  }

  /**
   * @param {Object} options 
   * @param {String} options.message will be parsed to HTML
   * @param {String} [options.level] info|error|success
   * @param {Boolean} [options.removeOption] wether or not to show the ✖
   * @param {Number} [options.time] when declared, notification will disappear after Xms
   * @returns this
   */
  message({ level = 'info', message, time, removeOption = true }) {
    const messageNode = document.createElement('div');
    messageNode.classList.add('notify', `notify--${level}`);
    messageNode.innerHTML = message;

    this._append(messageNode);

    if (removeOption) this._addRemoveOption(messageNode);
    if (time) setTimeout(() => messageNode.remove(), time);
    return this;
  }

  /**
   * clears the node from all messages
   * @returns this
   */
  clear() {
    this.node.innerHTML = '';
    this.messages = [];
    return this;
  }

  _addRemoveOption(node) {
    const removeNode = document.createElement('button');
    removeNode.innerHTML = '✖';
    removeNode.classList.add('nobutton', 'link', 'notify__button');
    removeNode.addEventListener('click', () => node.remove());
    node.append(removeNode);
  }

  _append(node) {
    this.messages.push(node);
    this.node.append(node);
  }
}
