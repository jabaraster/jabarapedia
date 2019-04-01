const sut = require('../.webpack/dao')

sut.saveLanguage({
    meta: {
        lightWeight: false,
        staticTyping: true,
        functional: true,
        objectOriented: false,
    },
    name: 'Haskell',
    path: 'haskell2',
    impression: 'max!!',
})
    .then(res => {
        console.log(res)
    })
    .catch(err => {
        console.log('!!!!!!!!!!')
        console.log(err)
    })