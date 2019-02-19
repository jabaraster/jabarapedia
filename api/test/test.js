const sut = require('../.webpack/dao')

sut.postLanguage({
    meta: {
        lightWeight: false,
        staticTyping: true,
    },
    name: 'Haskell',
    path: 'haskell',
    impression: 'max!!',
})
    .then(res => {
        console.log(res)
    })
    .catch(err => {
        console.log('!!!!!!!!!!')
        console.log(err)
    })